require "./base.cr"

module Invidious::Database::Videos
  module DBCache
    extend self

    def set(video : Video, expire_time)
      if redis = REDIS_DB
        redis.set(video.id, video.info.to_json, expire_time)
        redis.set(video.id + ":time", video.updated, expire_time)
      else
        request = <<-SQL
          INSERT INTO videos
          VALUES ($1, $2, $3)
          ON CONFLICT (id) DO NOTHING
        SQL

        PG_DB.exec(request, video.id, video.info.to_json, video.updated)
      end
    end

    def del(id : String)
      if redis = REDIS_DB
        redis.del(id)
        redis.del(id + ":time")
      else
        request = <<-SQL
          DELETE FROM videos *
          WHERE id = $1
        SQL

        PG_DB.exec(request, id)
      end
    end

    def get(id : String)
      if redis = REDIS_DB
        info = redis.get(id)
        time = redis.get(id + ":time")
        if info && time
          return Video.new({
            id:      id,
            info:    JSON.parse(info).as_h,
            updated: Time.parse(time, "%Y-%m-%d %H:%M:%S %z", Time::Location::UTC),
          })
        else
          return nil
        end
      else
        request = <<-SQL
          SELECT * FROM videos
          WHERE id = $1
        SQL

        return PG_DB.query_one?(request, id, as: Video)
      end
    end
  end

  extend self

  def insert(video : Video)
    DBCache.set(video: video, expire_time: 14400) if CONFIG.video_cache
  end

  def delete(id)
    DBCache.del(id)
  end

  def delete_expired
    request = <<-SQL
      DELETE FROM videos *
      WHERE updated < (now() - interval '6 hours')
    SQL

    PG_DB.exec(request)
  end

  def update(video : Video)
    request = <<-SQL
      UPDATE videos
      SET (id, info, updated) = ($1, $2, $3)
      WHERE id = $1
    SQL

    PG_DB.exec(request, video.id, video.info.to_json, video.updated)
  end

  def select(id : String) : Video?
    return DBCache.get(id)
  end
end
