# name: Watch Category
# about: Watches a category for all the users in a particular group
# version: 0.3
# authors: Arpit Jalan
# url: https://github.com/discourse/discourse-watch-category-mcneel

module ::WatchCategory

  def self.watch_category!
    groups_cats = {
      # "group" => ["category", "another-top-level-category", ["parent-category", "sub-category"] ],
      "coordinating-cmte" => [ ["closed-groups", "coordinating-committee"] ],
      "digcol-cmte" => [ ["closed-groups", "digital-collections-committee"] ],
      "digped-cmte" => [ ["closed-groups", "digital-pedagogy-committee"] ],
      "digschol-cmte" => [ ["closed-groups", "digital-scholarship-committee"] ],
      "eresources-cmte" => [ ["closed-groups", "e-resources-committee"], ["libraries", "buyers-group"] ],
      "infolit-cmte" => [ ["closed-groups", "information-literacy-committee"] ],
      "inst-research-cmte" => [ ["closed-groups", "institutional-research-assessment-committee"] ],
      "oclc-cmte" => [ ["closed-groups", "oclc-programs-committee"] ],
      "profdev-cmte" => [ ["closed-groups", "professional-development-committee"] ],
      "grant-review-cmte" => [ ["closed-groups", "grant-review-cmte"] ],
      "amical-2018-joint-org" => [ ["closed-groups", "amical-2018-joint-org"] ],
      "amical-2018-program-cmte" => [ ["closed-groups", "amical-2018-program-cmte"] ],
      "dhsi-2018-cohort" => [ ["closed-groups", "dhsi-2018-cohort"] ],
      "chairs" => [ ["closed-groups", "chairs"] ],
      "lib-buyers" => [ ["buyers-group"] ]
      # "everyone" makes every user watch the listed categories
      # "everyone" => [ "announcements" ]
    }
    WatchCategory.change_notification_pref_for_group(groups_cats, :watching)

    groups_cats = {
      "infolit" => [ ["interest-groups", "information-literacy"] ],
      "coordinating-cmte" => [ "announcements" ],
      "representatives" => [ "announcements" ]
    }
    WatchCategory.change_notification_pref_for_group(groups_cats, :watching_first_post)
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
      every 6.hours

      def execute(args)
        WatchCategory.watch_category!
      end
    end
  end
end
