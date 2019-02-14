# name: Watch Category
# about: Watches a category for all the users in a particular group
# version: 0.3
# authors: Arpit Jalan
# url: https://github.com/discourse/discourse-watch-category-mcneel

module ::WatchCategory

  def self.watch_category!
    groups_cats = {
      # "group" => ["category", "another-top-level-category", ["parent-category", "sub-category"] ],
      "gl_backend" => [ "group-leaders", ["group-leaders", "gls-backend"] ],
      "gl_devops" => [ "group-leaders", ["group-leaders", "gls-devops"] ],
      "gl_frontend" => [ "group-leaders", ["group-leaders", "gls-frontend"] ],
      "gl_mobile" => [ "group-leaders", ["group-leaders", "gls-mobile"] ],
      "mgmt_admin" => [ "management" ],
      "mgmt_finance" => [ ["management", "finance"] ],
      "mgmt_hr" => [ ["management", "hr"] ],
      "mgmt_sales" => [ ["management", "sales"] ],
      "tech_circle_backend" => [ "tech-circle", ["tech-circle", "backend-tech-circle"] ],
      "tech_circle_devops" => [ "tech-circle", ["tech-circle", "devops-tech-circle"] ],
      "tech_circle_frontend" => [ "tech-circle", ["tech-circle", "frontent-tech-circle"] ],
      "tech_circle_mobile" => [ "tech-circle", ["tech-circle", "mobile-tech-circle"] ],
      "tech_circle_leaders" => [ ["management", "tech-circle-leaders"] ],
      "tech_group_backend" => [ "technology-groups", ["technology-groups", "backend"] ],
      "tech_group_devops" => [ "technology-groups", ["technology-groups", "devops"] ],
      "tech_group_frontend" => [ "technology-groups", ["technology-groups", "frontend"] ],
      "tech_group_mobile" => [ "technology-groups", ["technology-groups", "mobile"] ],
      "tech_group_leaders" => [ ["management", "group-routine-leaders"] ],
      # "everyone" makes every user watch the listed categories
      "everyone" => [ "management" ]
    }
    WatchCategory.change_notification_pref_for_group(groups_cats, :watching)
  end

  def self.change_notification_pref_for_group(groups_cats, pref)
    groups_cats.each do |group_name, cats|
      cats.each do |cat_slug|

        # If a category is an array, the first value is treated as the top-level category and the second as the sub-category
        if cat_slug.respond_to?(:each)
          category = Category.find_by_slug(cat_slug[1], cat_slug[0])
        else
          category = Category.find_by_slug(cat_slug)
        end
        group = Group.find_by_name(group_name)

        unless category.nil? || group.nil?
          if group_name == "everyone"
            User.all.each do |user|
              watched_categories = CategoryUser.lookup(user, pref).pluck(:category_id)
              CategoryUser.set_notification_level_for_category(user, CategoryUser.notification_levels[pref], category.id) unless watched_categories.include?(category.id)
            end
          else
            group.users.each do |user|
              watched_categories = CategoryUser.lookup(user, pref).pluck(:category_id)
              CategoryUser.set_notification_level_for_category(user, CategoryUser.notification_levels[pref], category.id) unless watched_categories.include?(category.id)
            end
          end
        end

      end
    end
  end

end

after_initialize do
  module ::WatchCategory
    class WatchCategoryJob < ::Jobs::Scheduled
      every 1.hours

      def execute(args)
        WatchCategory.watch_category!
      end
    end
  end
end
