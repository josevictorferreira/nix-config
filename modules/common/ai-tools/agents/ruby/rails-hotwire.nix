{ config
, lib
, inputs
, ...
}:

let
  agentName = "rails-hotwire";
  cfg = config.jvf.aiTools.agents."${agentName}";
  agentFullName = inputs.lib.strings.kebabToHuman agentName;
  agentOptions = rec {
    name = agentName;
    description = "Rails frontend development guidelines using Hotwire (Turbo + Stimulus), Tailwind CSS, and ViewComponent. Modern patterns for server-rendered HTML with progressive enhancement, zero-build frontend architecture, and Rails conventions. Use when creating views, components, Stimulus controllers, partials, or working with frontend code.";
    tools = [
      "Read"
      "Write"
      "Bash"
      "WebFetch"
      "Blob"
    ];
    tags = [
      "explorer"
      "documentation"
      "browser"
    ];
    mode = "subagent";
    references = {
      complete_examples = ''
        # Complete Examples

        Full working examples demonstrating Rails frontend patterns. Always use the `chrome-devtools` tool to debug directly in the browser.

        ## Example 1: CRUD with Turbo Frames

        ### Index View with Inline Editing

        ```erb
        <%# app/views/posts/index.html.erb %>
        <div class="max-w-6xl mx-auto p-6">
          <div class="flex justify-between items-center mb-6">
            <h1 class="text-3xl font-bold">Posts</h1>

            <%= link_to "New Post",
                        new_post_path,
                        data: { turbo_frame: "modal" },
                        class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded" %>
          </div>

          <div id="posts" class="space-y-4">
            <%= render @posts %>
          </div>
        </div>

        <%# Modal placeholder %>
        <%= turbo_frame_tag "modal" %>
        ```

        ### Post Partial

        ```erb
        <%# app/views/posts/_post.html.erb %>
        <%= turbo_frame_tag dom_id(post) do %>
          <div class="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow">
            <div class="flex justify-between items-start">
              <div class="flex-1">
                <h2 class="text-2xl font-bold mb-2"><%= post.title %></h2>
                <p class="text-gray-700 mb-4"><%= truncate(post.content, length: 200) %></p>
                <p class="text-sm text-gray-500">
                  Posted <%= time_ago_in_words(post.created_at) %> ago
                </p>
              </div>

              <div class="flex gap-2 ml-4">
                <%= link_to "Edit",
                            edit_post_path(post),
                            class: "text-blue-500 hover:text-blue-700" %>

                <%= button_to "Delete",
                              post_path(post),
                              method: :delete,
                              form: { data: { turbo_confirm: "Are you sure?" } },
                              class: "text-red-500 hover:text-red-700" %>
              </div>
            </div>
          </div>
        <% end %>
        ```

        ### Edit View (Inline)

        ```erb
        <%# app/views/posts/edit.html.erb %>
        <%= turbo_frame_tag dom_id(@post) do %>
          <div class="bg-white rounded-lg shadow-md p-6">
            <h2 class="text-2xl font-bold mb-4">Edit Post</h2>

            <%= form_with model: @post, class: "space-y-4" do |f| %>
              <div>
                <%= f.label :title, class: "block font-bold mb-2" %>
                <%= f.text_field :title,
                                 class: "border rounded-lg p-2 w-full focus:ring-2 focus:ring-blue-500" %>
              </div>

              <div>
                <%= f.label :content, class: "block font-bold mb-2" %>
                <%= f.text_area :content,
                                rows: 6,
                                class: "border rounded-lg p-2 w-full focus:ring-2 focus:ring-blue-500" %>
              </div>

              <div class="flex gap-2">
                <%= f.submit "Save",
                             class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded" %>

                <%= link_to "Cancel",
                            post_path(@post),
                            class: "bg-gray-300 hover:bg-gray-400 text-gray-800 font-bold py-2 px-4 rounded" %>
              </div>
            <% end %>
          </div>
        <% end %>
        ```

        ### New Post Modal

        ```erb
        <%# app/views/posts/new.html.erb %>
        <%= turbo_frame_tag "modal" do %>
          <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
               data-controller="modal"
               data-action="click->modal#closeBackground">

            <div class="bg-white rounded-lg shadow-xl max-w-2xl w-full m-4"
                 data-modal-target="content">
              <div class="p-6">
                <div class="flex justify-between items-center mb-4">
                  <h2 class="text-2xl font-bold">New Post</h2>

                  <%= link_to posts_path,
                              class: "text-gray-500 hover:text-gray-700" do %>
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  <% end %>
                </div>

                <%= form_with model: @post, class: "space-y-4" do |f| %>
                  <div>
                    <%= f.label :title, class: "block font-bold mb-2" %>
                    <%= f.text_field :title,
                                     class: "border rounded-lg p-2 w-full focus:ring-2 focus:ring-blue-500" %>
                  </div>

                  <div>
                    <%= f.label :content, class: "block font-bold mb-2" %>
                    <%= f.text_area :content,
                                    rows: 8,
                                    class: "border rounded-lg p-2 w-full focus:ring-2 focus:ring-blue-500" %>
                  </div>

                  <div class="flex gap-2">
                    <%= f.submit "Create Post",
                                 class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded" %>

                    <%= link_to "Cancel",
                                posts_path,
                                class: "bg-gray-300 hover:bg-gray-400 text-gray-800 font-bold py-2 px-4 rounded" %>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        <% end %>
        ```

        ### Modal Stimulus Controller

        ```javascript
        // app/javascript/controllers/modal_controller.js
        import { Controller } from "@hotwired/stimulus";

        export default class extends Controller {
          static targets = ["content"];

          closeBackground(event) {
            if (event.target === this.element) {
              this.close();
            }
          }

          close() {
            this.element.remove();
          }

          // Close on Escape key
          connect() {
            this.boundHandleEscape = this.handleEscape.bind(this);
            document.addEventListener("keydown", this.boundHandleEscape);
          }

          disconnect() {
            document.removeEventListener("keydown", this.boundHandleEscape);
          }

          handleEscape(event) {
            if (event.key === "Escape") {
              this.close();
            }
          }
        }
        ```

        ### Controller with Turbo Streams

        ```ruby
        # app/controllers/posts_controller.rb
        class PostsController < ApplicationController
          def index
            @posts = Post.order(created_at: :desc)
          end

          def new
            @post = Post.new
          end

          def create
            @post = Post.new(post_params)

            respond_to do |format|
              if @post.save
                format.turbo_stream do
                  render turbo_stream: [
                    turbo_stream.prepend("posts", partial: "posts/post", locals: { post: @post }),
                    turbo_stream.remove("modal")
                  ]
                end
                format.html { redirect_to posts_path, notice: "Post created!" }
              else
                format.html { render :new, status: :unprocessable_entity }
              end
            end
          end

          def edit
            @post = Post.find(params[:id])
          end

          def update
            @post = Post.find(params[:id])

            respond_to do |format|
              if @post.update(post_params)
                format.turbo_stream do
                  render turbo_stream: turbo_stream.replace(
                    dom_id(@post),
                    partial: "posts/post",
                    locals: { post: @post }
                  )
                end
                format.html { redirect_to @post, notice: "Post updated!" }
              else
                format.html { render :edit, status: :unprocessable_entity }
              end
            end
          end

          def destroy
            @post = Post.find(params[:id])
            @post.destroy

            respond_to do |format|
              format.turbo_stream { render turbo_stream: turbo_stream.remove(dom_id(@post)) }
              format.html { redirect_to posts_path, notice: "Post deleted!" }
            end
          end

          private

          def post_params
            params.require(:post).permit(:title, :content)
          end
        end
        ```

        ---

        ## Example 2: Real-time Comments with Action Cable

        ### Post Show with Comments

        ```erb
        <%# app/views/posts/show.html.erb %>
        <div class="max-w-4xl mx-auto p-6">
          <article class="bg-white rounded-lg shadow-md p-8 mb-6">
            <h1 class="text-4xl font-bold mb-4"><%= @post.title %></h1>
            <div class="prose max-w-none">
              <%= simple_format @post.content %>
            </div>
          </article>

          <section class="bg-white rounded-lg shadow-md p-6">
            <h2 class="text-2xl font-bold mb-4">Comments</h2>

            <%# Subscribe to real-time updates %>
            <%= turbo_stream_from @post %>

            <%# New comment form %>
            <%= turbo_frame_tag "new_comment" do %>
              <%= render "comments/form", post: @post, comment: Comment.new %>
            <% end %>

            <%# Comments list %>
            <div id="comments" class="space-y-4 mt-6">
              <%= render @post.comments.order(created_at: :desc) %>
            </div>
          </section>
        </div>
        ```

        ### Comment Partial

        ```erb
        <%# app/views/comments/_comment.html.erb %>
        <%= turbo_frame_tag dom_id(comment) do %>
          <div class="bg-gray-50 rounded-lg p-4">
            <div class="flex justify-between items-start mb-2">
              <strong class="text-gray-900"><%= comment.author_name %></strong>
              <span class="text-sm text-gray-500">
                <%= time_ago_in_words(comment.created_at) %> ago
              </span>
            </div>

            <p class="text-gray-700"><%= comment.content %></p>

            <div class="mt-2 flex gap-4">
              <%= link_to "Edit",
                          edit_post_comment_path(comment.post, comment),
                          class: "text-blue-500 hover:text-blue-700 text-sm" %>

              <%= button_to "Delete",
                            post_comment_path(comment.post, comment),
                            method: :delete,
                            form: { data: { turbo_confirm: "Are you sure?" } },
                            class: "text-red-500 hover:text-red-700 text-sm" %>
            </div>
          </div>
        <% end %>
        ```

        ### Comment Form

        ```erb
        <%# app/views/comments/_form.html.erb %>
        <%= form_with model: [post, comment],
                      data: { controller: "reset-form" },
                      class: "space-y-4" do |f| %>

          <div>
            <%= f.label :author_name, "Your Name", class: "block font-bold mb-2" %>
            <%= f.text_field :author_name,
                             class: "border rounded-lg p-2 w-full" %>
          </div>

          <div>
            <%= f.label :content, "Comment", class: "block font-bold mb-2" %>
            <%= f.text_area :content,
                            rows: 3,
                            class: "border rounded-lg p-2 w-full" %>
          </div>

          <%= f.submit "Add Comment",
                       class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded" %>
        <% end %>
        ```

        ### Comment Model with Broadcasting

        ```ruby
        # app/models/comment.rb
        class Comment < ApplicationRecord
          belongs_to :post

          validates :author_name, :content, presence: true

          # Broadcast changes to all connected clients
          after_create_commit { broadcast_prepend_to post, target: "comments" }
          after_update_commit { broadcast_replace_to post }
          after_destroy_commit { broadcast_remove_to post }
        end
        ```

        ### Comments Controller

        ```ruby
        # app/controllers/comments_controller.rb
        class CommentsController < ApplicationController
          before_action :set_post

          def create
            @comment = @post.comments.build(comment_params)

            if @comment.save
              # The after_create_commit callback handles broadcasting
              respond_to do |format|
                format.turbo_stream do
                  render turbo_stream: turbo_stream.replace(
                    "new_comment",
                    partial: "comments/form",
                    locals: { post: @post, comment: Comment.new }
                  )
                end
                format.html { redirect_to @post, notice: "Comment added!" }
              end
            else
              render :new, status: :unprocessable_entity
            end
          end

          def edit
            @comment = @post.comments.find(params[:id])
          end

          def update
            @comment = @post.comments.find(params[:id])

            if @comment.update(comment_params)
              # The after_update_commit callback handles broadcasting
              respond_to do |format|
                format.turbo_stream
                format.html { redirect_to @post, notice: "Comment updated!" }
              end
            else
              render :edit, status: :unprocessable_entity
            end
          end

          def destroy
            @comment = @post.comments.find(params[:id])
            @comment.destroy

            # The after_destroy_commit callback handles broadcasting
            respond_to do |format|
              format.turbo_stream
              format.html { redirect_to @post, notice: "Comment deleted!" }
            end
          end

          private

          def set_post
            @post = Post.find(params[:post_id])
          end

          def comment_params
            params.require(:comment).permit(:author_name, :content)
          end
        end
        ```

        ### Reset Form Controller

        ```javascript
        // app/javascript/controllers/reset_form_controller.js
        import { Controller } from "@hotwired/stimulus";

        export default class extends Controller {
          connect() {
            // Listen for turbo:submit-end event
            this.element.addEventListener(
              "turbo:submit-end",
              this.handleSubmit.bind(this),
            );
          }

          handleSubmit(event) {
            // Reset form if submission was successful
            if (event.detail.success) {
              this.element.reset();
            }
          }
        }
        ```

        ---

        ## Example 3: Search with Auto-complete

        ### Search Form

        ```erb
        <%# app/views/posts/index.html.erb %>
        <div class="max-w-6xl mx-auto p-6">
          <div class="mb-6">
            <%= form_with url: posts_path,
                          method: :get,
                          data: {
                            controller: "search",
                            turbo_frame: "search_results"
                          },
                          class: "relative" do |f| %>

              <div class="relative">
                <%= f.search_field :query,
                                   value: params[:query],
                                   placeholder: "Search posts...",
                                   data: {
                                     search_target: "input",
                                     action: "input->search#search"
                                   },
                                   class: "border rounded-lg p-3 w-full pr-10" %>

                <div class="absolute right-3 top-3"
                     data-search-target="spinner"
                     style="display: none;">
                  <svg class="animate-spin h-5 w-5 text-gray-500" fill="none" viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                </div>
              </div>
            <% end %>
          </div>

          <%= turbo_frame_tag "search_results" do %>
            <div id="posts" class="space-y-4">
              <%= render @posts %>
            </div>
          <% end %>
        </div>
        ```

        ### Search Controller

        ```javascript
        // app/javascript/controllers/search_controller.js
        import { Controller } from "@hotwired/stimulus";

        export default class extends Controller {
          static targets = ["input", "spinner"];
          static values = {
            delay: { type: Number, default: 300 },
          };

          connect() {
            this.timeout = null;
          }

          disconnect() {
            clearTimeout(this.timeout);
          }

          search() {
            clearTimeout(this.timeout);

            // Show spinner
            this.spinnerTarget.style.display = "block";

            // Debounce search
            this.timeout = setTimeout(() => {
              this.element.requestSubmit();
            }, this.delayValue);
          }
        }
        ```

        ### Controller with Turbo Frame Response

        ```ruby
        # app/controllers/posts_controller.rb
        class PostsController < ApplicationController
          def index
            @posts = if params[:query].present?
              Post.where("title ILIKE ? OR content ILIKE ?",
                         "%#{params[:query]}%",
                         "%#{params[:query]}%")
                  .order(created_at: :desc)
            else
              Post.order(created_at: :desc)
            end

            # Turbo Frame will automatically extract the matching frame
            render :index
          end
        end
        ```

        ---

        These examples demonstrate real-world patterns you'll use in Rails applications with Hotwire. They show progressive enhancement, real-time updates, and minimal JavaScript for maximum effect.
      '';

      ###################################################################
      stimulus_guide = ''
        # Stimulus Guide

        Stimulus is a JavaScript framework that enhances server-rendered HTML with just enough JavaScript to make your application feel responsive and modern.

        ## Core Concepts

        Stimulus has three main concepts:

        1. **Controllers** - JavaScript classes that enhance HTML elements
        2. **Actions** - How events trigger controller methods
        3. **Targets** - Named DOM elements you can reference in your controller

        Plus two additional concepts: 4. **Values** - Configuration data with automatic type conversion 5. **Classes** - CSS class names you can reference

        ---

        ## Setting Up a Controller

        ### 1. Create the Controller File

        ```javascript
        // app/javascript/controllers/hello_controller.js
        import { Controller } from "@hotwired/stimulus";

        export default class extends Controller {
          connect() {
            console.log("Hello, Stimulus");
          }
        }
        ```

        ### 2. Register (Auto-registered via index.js)

        Controllers in `app/javascript/controllers/` are automatically registered if you're using the standard Rails 7+ setup.

        ### 3. Connect to HTML

        ```erb
        <div data-controller="hello">
          This div is now enhanced by Stimulus!
        </div>
        ```

        ---

        ## Targets

        Targets let you reference specific elements within your controller's scope.

        ### Define Targets

        ```javascript
        // app/javascript/controllers/slideshow_controller.js
        import { Controller } from "@hotwired/stimulus";

        export default class extends Controller {
          static targets = ["slide", "caption"];

          connect() {
            console.log("Slides:", this.slideTargets.length);
            console.log("Caption:", this.captionTarget.textContent);
          }

          // Check if target exists
          hasCaption() {
            return this.hasCaptionTarget;
          }
        }
        ```

        ### Use in HTML

        ```erb
        <div data-controller="slideshow">
          <div data-slideshow-target="slide">Slide 1</div>
          <div data-slideshow-target="slide">Slide 2</div>
          <div data-slideshow-target="slide">Slide 3</div>

          <p data-slideshow-target="caption">Caption text</p>
        </div>
        ```

        ### Target Methods

        ```javascript
        // Single target (throws if missing)
        this.slideTarget;

        // Check existence
        this.hasSlideTarget; // boolean

        // All targets
        this.slideTargets; // array

        // Find target
        this.slideTargets.find((el) => el.dataset.active === "true");
        ```

        ---

        ## Actions

        Actions connect DOM events to controller methods.

        ### Basic Action

        ```erb
        <div data-controller="counter">
          <button data-action="click->counter#increment">+</button>
          <span data-counter-target="count">0</span>
        </div>
        ```

        ```javascript
        // app/javascript/controllers/counter_controller.js
        import { Controller } from "@hotwired/stimulus";

        export default class extends Controller {
          static targets = ["count"];

          increment(event) {
            const current = parseInt(this.countTarget.textContent);
            this.countTarget.textContent = current + 1;

            // Access the DOM event
            console.log("Clicked element:", event.currentTarget);
          }
        }
        ```

        ### Action Syntax

        ```
        data-action="[event->]controller#method[@window|@document]"
        ```

        Examples:

        ```erb
        <%# Click is the default for buttons %>
        <button data-action="counter#increment">+</button>

        <%# Explicit event %>
        <input data-action="input->search#query">

        <%# Multiple actions %>
        <input data-action="focus->form#highlight blur->form#reset">

        <%# Global events %>
        <div data-action="resize@window->layout#adjust">

        <%# Prevent default %>
        <form data-action="submit->form#save:prevent">

        <%# Custom event modifiers %>
        <input data-action="keydown.enter->form#submit">
        ```

        ### Event Modifiers

        ```erb
        <%# Prevent default %>
        <form data-action="submit->form#save:prevent">

        <%# Stop propagation %>
        <button data-action="click->menu#toggle:stop">

        <%# Run once %>
        <button data-action="click->setup#initialize:once">

        <%# Keyboard filters %>
        <input data-action="keydown.enter->form#submit">
        <input data-action="keydown.esc->modal#close">
        <input data-action="keydown.meta+s->editor#save">
        ```

        ---

        ## Values

        Values provide a type-safe way to pass configuration to controllers.

        ### Define Values

        ```javascript
        // app/javascript/controllers/timer_controller.js
        import { Controller } from "@hotwired/stimulus";

        export default class extends Controller {
          static values = {
            duration: Number, // Required type
            autoStart: { type: Boolean, default: false }, // With default
            message: String,
            data: Object,
            items: Array,
          };

          connect() {
            console.log(this.durationValue); // Access value
            console.log(this.hasMessageValue); // Check existence

            if (this.autoStartValue) {
              this.start();
            }
          }

          // Called when value changes
          durationValueChanged(value, previousValue) {
            console.log(`Duration changed from ''${previousValue} to ''${value}`);
          }
        }
        ```

        ### Use in HTML

        ```erb
        <div data-controller="timer"
             data-timer-duration-value="60"
             data-timer-auto-start-value="true"
             data-timer-message-value="Time's up!">
          Timer content
        </div>
        ```

        ### Update Values from Controller

        ```javascript
        increment() {
          this.durationValue = this.durationValue + 10
          // This triggers durationValueChanged callback
        }
        ```

        ### Value Types

        | Type      | Example                                | Notes                         |
        | --------- | -------------------------------------- | ----------------------------- |
        | `String`  | `"hello"`                              | Default type if not specified |
        | `Number`  | `42`                                   | Parsed with `Number()`        |
        | `Boolean` | `true`, `false`, `"true"`, `"1"`, `""` | Falsy values: false, 0, ""    |
        | `Object`  | `{"key": "value"}`                     | Parsed as JSON                |
        | `Array`   | `[1, 2, 3]`                            | Parsed as JSON                |

        ---

        ## Classes

        Classes let you reference CSS class names from your controller.

        ### Define Classes

        ```javascript
        // app/javascript/controllers/dropdown_controller.js
        import { Controller } from "@hotwired/stimulus";

        export default class extends Controller {
          static classes = ["open", "closed"];
          static targets = ["menu"];

          toggle() {
            if (this.menuTarget.classList.contains(this.openClass)) {
              this.menuTarget.classList.remove(this.openClass);
              this.menuTarget.classList.add(this.closedClass);
            } else {
              this.menuTarget.classList.remove(this.closedClass);
              this.menuTarget.classList.add(this.openClass);
            }
          }
        }
        ```

        ### Use in HTML

        ```erb
        <div data-controller="dropdown"
             data-dropdown-open-class="block"
             data-dropdown-closed-class="hidden">

          <button data-action="dropdown#toggle">Toggle</button>

          <div data-dropdown-target="menu"
               class="hidden">
            Menu content
          </div>
        </div>
        ```

        ---

        ## Lifecycle Callbacks

        Stimulus controllers have lifecycle methods:

        ```javascript
        export default class extends Controller {
          // Called when controller is connected to the DOM
          connect() {
            console.log("Connected!");
            this.setupEventListeners();
          }

          // Called when controller is disconnected from the DOM
          disconnect() {
            console.log("Disconnected!");
            this.cleanupEventListeners();
          }

          // Called when an element appears/disappears
          slideTargetConnected(element) {
            console.log("Slide target connected:", element);
          }

          slideTargetDisconnected(element) {
            console.log("Slide target disconnected:", element);
          }
        }
        ```

        **Important:** Always clean up in `disconnect()`:

        - Remove event listeners added in `connect()`
        - Clear timers/intervals
        - Cancel pending requests

        ---

        ## Complete Example: Dropdown

        ```javascript
        // app/javascript/controllers/dropdown_controller.js
        import { Controller } from "@hotwired/stimulus";

        export default class extends Controller {
          static targets = ["menu"];
          static classes = ["open"];
          static values = {
            closeOnClickOutside: { type: Boolean, default: true },
          };

          connect() {
            if (this.closeOnClickOutsideValue) {
              this.boundHandleClickOutside = this.handleClickOutside.bind(this);
            }
          }

          disconnect() {
            this.removeClickOutsideListener();
          }

          toggle(event) {
            event.preventDefault();

            if (this.isOpen) {
              this.close();
            } else {
              this.open();
            }
          }

          open() {
            this.menuTarget.classList.add(this.openClass);

            if (this.closeOnClickOutsideValue) {
              setTimeout(() => {
                document.addEventListener("click", this.boundHandleClickOutside);
              }, 0);
            }
          }

          close() {
            this.menuTarget.classList.remove(this.openClass);
            this.removeClickOutsideListener();
          }

          handleClickOutside(event) {
            if (!this.element.contains(event.target)) {
              this.close();
            }
          }

          removeClickOutsideListener() {
            if (this.boundHandleClickOutside) {
              document.removeEventListener("click", this.boundHandleClickOutside);
            }
          }

          get isOpen() {
            return this.menuTarget.classList.contains(this.openClass);
          }
        }
        ```

        ```erb
        <div data-controller="dropdown"
             data-dropdown-open-class="block"
             data-dropdown-close-on-click-outside-value="true"
             class="relative">

          <button data-action="dropdown#toggle"
                  class="bg-blue-500 text-white px-4 py-2 rounded">
            Dropdown
          </button>

          <div data-dropdown-target="menu"
               class="hidden absolute mt-2 bg-white shadow-lg rounded">
            <a href="#" class="block px-4 py-2 hover:bg-gray-100">Item 1</a>
            <a href="#" class="block px-4 py-2 hover:bg-gray-100">Item 2</a>
            <a href="#" class="block px-4 py-2 hover:bg-gray-100">Item 3</a>
          </div>
        </div>
        ```

        ---

        ## Common Patterns

        ### Auto-save Form

        ```javascript
        // app/javascript/controllers/autosave_controller.js
        import { Controller } from "@hotwired/stimulus";

        export default class extends Controller {
          static targets = ["status"];
          static values = {
            url: String,
            delay: { type: Number, default: 1000 },
          };

          connect() {
            this.timeout = null;
          }

          disconnect() {
            clearTimeout(this.timeout);
          }

          save() {
            clearTimeout(this.timeout);

            this.timeout = setTimeout(() => {
              this.performSave();
            }, this.delayValue);
          }

          async performSave() {
            const formData = new FormData(this.element);
            this.showStatus("Saving...");

            try {
              const response = await fetch(this.urlValue, {
                method: "PATCH",
                body: formData,
                headers: {
                  "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
                },
              });

              if (response.ok) {
                this.showStatus("Saved!", "success");
              } else {
                this.showStatus("Error saving", "error");
              }
            } catch (error) {
              this.showStatus("Error saving", "error");
            }
          }

          showStatus(message, type = "info") {
            if (this.hasStatusTarget) {
              this.statusTarget.textContent = message;
              this.statusTarget.className = `status-''${type}`;
            }
          }
        }
        ```

        ```erb
        <%= form_with model: @post,
                      data: {
                        controller: "autosave",
                        autosave_url_value: post_path(@post),
                        action: "input->autosave#save"
                      } do |f| %>

          <%= f.text_field :title %>
          <%= f.text_area :content %>

          <span data-autosave-target="status"></span>
        <% end %>
        ```

        ### Character Counter

        ```javascript
        // app/javascript/controllers/character_counter_controller.js
        import { Controller } from "@hotwired/stimulus";

        export default class extends Controller {
          static targets = ["input", "count"];
          static values = {
            max: { type: Number, default: 280 },
          };

          connect() {
            this.updateCount();
          }

          updateCount() {
            const length = this.inputTarget.value.length;
            const remaining = this.maxValue - length;

            this.countTarget.textContent = remaining;

            if (remaining < 0) {
              this.countTarget.classList.add("text-red-500");
            } else {
              this.countTarget.classList.remove("text-red-500");
            }
          }
        }
        ```

        ```erb
        <div data-controller="character-counter"
             data-character-counter-max-value="280">

          <%= text_area_tag :content, nil,
                            data: {
                              character_counter_target: "input",
                              action: "input->character-counter#updateCount"
                            },
                            class: "border rounded p-2 w-full" %>

          <div class="text-sm text-gray-600">
            <span data-character-counter-target="count">280</span> characters remaining
          </div>
        </div>
        ```

        ---

        ## Best Practices

        1. **Keep controllers small** - One clear responsibility per controller
        2. **Clean up in disconnect()** - Remove listeners, clear timers
        3. **Use values for configuration** - Not data attributes
        4. **Use targets sparingly** - Don't over-target everything
        5. **Bind event handlers** - If you need to remove them later
        6. **Test without JavaScript** - Progressive enhancement
        7. **Name actions clearly** - `toggle`, `open`, `close` not `handle`, `do`
        8. **Use Turbo first** - Only add Stimulus when you need client-side interactivity

        ---

        ## Debugging

        ```javascript
        connect() {
          console.log("Controller:", this.identifier)
          console.log("Element:", this.element)
          console.log("Targets:", this.constructor.targets)
          console.log("Values:", this.constructor.values)
        }
        ```

        Access from browser console:

        ```javascript
        // Get controller instance
        const element = document.querySelector("[data-controller='dropdown']");
        const controller = this.application.getControllerForElementAndIdentifier(
          element,
          "dropdown",
        );

        // Call methods
        controller.open();
        controller.close();
        ```

        ---

        ## Reference

        - [Stimulus Handbook](https://stimulus.hotwired.dev/handbook/introduction)
        - [Stimulus Reference](https://stimulus.hotwired.dev/reference/controllers)
        - Rails generators: `rails g stimulus [controller-name]`

      '';

      ###################################################################
      turbo_guide = ''
        # Turbo Guide (Hotwire)

        Turbo is part of Hotwire and provides three main tools: Turbo Drive, Turbo Frames, and Turbo Streams.

        ## Turbo Drive

        **What it does:** Automatically intercepts link clicks and form submissions, replacing page content without full reload.

        **Enabled by default** in Rails 7+. No configuration needed!

        ### Disabling Turbo Drive

        For specific links/forms that need full page reload:

        ```erb
        <%# Disable on a link %>
        <%= link_to "Full Reload", some_path, data: { turbo: false } %>

        <%# Disable on a form %>
        <%= form_with model: @post, data: { turbo: false } do |f| %>
          ...
        <% end %>

        <%# Disable for entire page (in head) %>
        <meta name="turbo-visit-control" content="reload">
        ```

        ### Turbo Drive Events

        Listen for page changes in Stimulus:

        ```javascript
        // app/javascript/controllers/page_controller.js
        import { Controller } from "@hotwired/stimulus";

        export default class extends Controller {
          connect() {
            document.addEventListener("turbo:load", this.onPageLoad);
            document.addEventListener("turbo:before-visit", this.beforeVisit);
          }

          disconnect() {
            document.removeEventListener("turbo:load", this.onPageLoad);
            document.removeEventListener("turbo:before-visit", this.beforeVisit);
          }

          onPageLoad = () => {
            console.log("Page loaded via Turbo");
          };

          beforeVisit = (event) => {
            // Can prevent navigation: event.preventDefault()
          };
        }
        ```

        ---

        ## Turbo Frames

        **What it does:** Updates only a specific part of the page instead of the whole page.

        ### Basic Turbo Frame

        ```erb
        <%# app/views/posts/show.html.erb %>
        <turbo-frame id="post_<%= @post.id %>">
          <h1><%= @post.title %></h1>
          <p><%= @post.content %></p>

          <%= link_to "Edit", edit_post_path(@post) %>
        </turbo-frame>

        <%# app/views/posts/edit.html.erb %>
        <turbo-frame id="post_<%= @post.id %>">
          <%= form_with model: @post do |f| %>
            <%= f.text_field :title %>
            <%= f.text_area :content %>
            <%= f.submit %>
          <% end %>
        </turbo-frame>
        ```

        **How it works:** Clicking "Edit" only replaces content inside the frame, not the whole page.

        ### Lazy Loading Frames

        Load content on-demand:

        ```erb
        <%# Loads immediately %>
        <turbo-frame id="eager_comments" src="<%= post_comments_path(@post) %>">
          Loading comments...
        </turbo-frame>

        <%# Loads when scrolled into view %>
        <turbo-frame id="lazy_related"
                     src="<%= related_posts_path(@post) %>"
                     loading="lazy">
          Loading related posts...
        </turbo-frame>
        ```

        ### Breaking Out of Frames

        Navigate the full page from within a frame:

        ```erb
        <turbo-frame id="modal">
          <%= link_to "Full Page", some_path, data: { turbo_frame: "_top" } %>

          <%# Or target a different frame %>
          <%= link_to "Other Frame", some_path, data: { turbo_frame: "other_frame" } %>
        </turbo-frame>
        ```

        ### Nested Frames

        Frames can be nested:

        ```erb
        <turbo-frame id="post_<%= @post.id %>">
          <h1><%= @post.title %></h1>

          <turbo-frame id="post_<%= @post.id %>_comments">
            <%= render @post.comments %>
          </turbo-frame>
        </turbo-frame>
        ```

        ---

        ## Turbo Streams

        **What it does:** Sends multiple updates to the page in one response (perfect for real-time updates).

        ### 7 Turbo Stream Actions

        1. **append** - Add to end of target
        2. **prepend** - Add to beginning of target
        3. **replace** - Replace entire target
        4. **update** - Replace target's content (keeps target element)
        5. **remove** - Remove target
        6. **before** - Insert before target
        7. **after** - Insert after target

        ### Controller Response

        ```ruby
        # app/controllers/posts_controller.rb
        class PostsController < ApplicationController
          def create
            @post = Post.new(post_params)

            respond_to do |format|
              if @post.save
                format.turbo_stream do
                  render turbo_stream: turbo_stream.prepend("posts", partial: "posts/post", locals: { post: @post })
                end
                format.html { redirect_to @post }
              else
                format.html { render :new, status: :unprocessable_entity }
              end
            end
          end

          def destroy
            @post = Post.find(params[:id])
            @post.destroy

            respond_to do |format|
              format.turbo_stream do
                render turbo_stream: turbo_stream.remove(@post)
              end
              format.html { redirect_to posts_path }
            end
          end
        end
        ```

        ### Turbo Stream Template

        Create a `.turbo_stream.erb` file:

        ```erb
        <%# app/views/posts/create.turbo_stream.erb %>
        <%= turbo_stream.prepend "posts", partial: "posts/post", locals: { post: @post } %>
        <%= turbo_stream.update "post_form", partial: "posts/form", locals: { post: Post.new } %>
        <%= turbo_stream.update "flash", partial: "shared/flash", locals: { notice: "Post created" } %>
        ```

        ### Multiple Stream Actions

        ```ruby
        # In controller
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.prepend("posts", partial: "posts/post", locals: { post: @post }),
            turbo_stream.update("post_count", html: Post.count),
            turbo_stream.remove("new_post_form")
          ]
        end
        ```

        ### Broadcast Updates (Real-time)

        For WebSocket updates across users:

        ```ruby
        # app/models/post.rb
        class Post < ApplicationRecord
          after_create_commit { broadcast_prepend_to "posts" }
          after_update_commit { broadcast_replace_to "posts" }
          after_destroy_commit { broadcast_remove_to "posts" }
        end
        ```

        Then in your view:

        ```erb
        <%# app/views/posts/index.html.erb %>
        <%= turbo_stream_from "posts" %>

        <div id="posts">
          <%= render @posts %>
        </div>
        ```

        ### Custom Turbo Stream Actions

        You can create custom actions with Stimulus:

        ```javascript
        // app/javascript/controllers/turbo_streams_controller.js
        import { Controller } from "@hotwired/stimulus";
        import { StreamActions } from "@hotwired/turbo";

        export default class extends Controller {
          connect() {
            StreamActions.console_log = function () {
              console.log(this.getAttribute("message"));
            };
          }
        }
        ```

        ---

        ## Common Patterns

        ### Inline Editing

        ```erb
        <%# app/views/posts/_post.html.erb %>
        <turbo-frame id="<%= dom_id(post) %>">
          <div class="bg-white p-4 rounded shadow">
            <h2 class="text-xl font-bold"><%= post.title %></h2>
            <p><%= post.content %></p>
            <%= link_to "Edit", edit_post_path(post), class: "text-blue-500" %>
          </div>
        </turbo-frame>

        <%# app/views/posts/edit.html.erb %>
        <turbo-frame id="<%= dom_id(@post) %>">
          <%= form_with model: @post do |f| %>
            <%= f.text_field :title, class: "border rounded p-2 w-full" %>
            <%= f.text_area :content, class: "border rounded p-2 w-full mt-2" %>
            <div class="mt-2">
              <%= f.submit "Save", class: "bg-blue-500 text-white px-4 py-2 rounded" %>
              <%= link_to "Cancel", post_path(@post), class: "text-gray-500 ml-2" %>
            </div>
          <% end %>
        </turbo-frame>
        ```

        ### Modal with Turbo Frame

        ```erb
        <%# app/views/layouts/application.html.erb %>
        <%= turbo_frame_tag "modal" %>

        <%# Link to open modal %>
        <%= link_to "New Post",
                    new_post_path,
                    data: { turbo_frame: "modal" },
                    class: "bg-blue-500 text-white px-4 py-2 rounded" %>

        <%# app/views/posts/new.html.erb %>
        <turbo-frame id="modal">
          <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center">
            <div class="bg-white p-6 rounded-lg shadow-xl max-w-2xl w-full">
              <h2 class="text-2xl font-bold mb-4">New Post</h2>

              <%= form_with model: @post do |f| %>
                <%# Form fields %>
                <%= f.submit %>
              <% end %>

              <%= link_to "Close", posts_path, class: "text-gray-500" %>
            </div>
          </div>
        </turbo-frame>
        ```

        ### Infinite Scroll

        ```erb
        <%# app/views/posts/index.html.erb %>
        <div id="posts">
          <%= render @posts %>
        </div>

        <%= turbo_frame_tag "pagination",
                            src: posts_path(page: @next_page),
                            loading: "lazy" if @next_page %>

        <%# When this frame loads, it should return more posts + new pagination frame %>
        ```

        ---

        ## Best Practices

        1. **Always match frame IDs** between pages
        2. **Use `dom_id` helper** for consistent IDs: `dom_id(post)` → `"post_123"`
        3. **Handle errors gracefully** - return Turbo Stream responses for errors too
        4. **Keep frames focused** - one logical section per frame
        5. **Lazy load heavy content** - use `loading="lazy"` for below-fold content
        6. **Use broadcasts for real-time** - prefer model callbacks for WebSocket updates
        7. **Test without JavaScript** - ensure basic functionality works, then enhance

        ---

        ## Troubleshooting

        ### Frame not updating?

        - Check frame IDs match exactly
        - Ensure both source and target have `<turbo-frame>` tags
        - Check server is returning HTML (not JSON)

        ### Form submits full page?

        - Make sure Turbo is not disabled
        - Check form is inside a Turbo Frame if you want frame-scoped updates

        ### Broadcasts not working?

        - Ensure Action Cable is configured
        - Check `turbo_stream_from` is in the view
        - Verify model callbacks are firing

        ---

        ## Reference

        - [Turbo Handbook](https://turbo.hotwired.dev/handbook/introduction)
        - [Turbo Streams Reference](https://turbo.hotwired.dev/reference/streams)
        - Rails `dom_id` helper for consistent IDs
        - Rails `turbo_stream` helper for responses
      '';
    };
    scripts = { };

    #####################################################################
    prompt = ''
      # ${agentFullName}

      ## Purpose

      Comprehensive guide for modern Rails frontend development using Hotwire (Turbo + Stimulus), Tailwind CSS, and server-side rendering. Emphasizes progressive enhancement, minimal JavaScript, and Rails conventions.

      ## When to Use This Skill

      - Creating new views or partials
      - Building Stimulus controllers
      - Working with Turbo Frames or Turbo Streams
      - Styling with Tailwind CSS
      - Creating ViewComponents
      - Adding frontend interactivity
      - Organizing frontend code
      - Performance optimization

      ---

      ## Quick Start

      ### New View Checklist

      Creating a view? Follow this checklist:

      - [ ] Use semantic HTML5 elements
      - [ ] Turbo Frame for interactive sections
      - [ ] Turbo Stream for real-time updates
      - [ ] Tailwind utility classes for styling
      - [ ] Minimal Stimulus controllers for interactivity
      - [ ] Partials for reusable components
      - [ ] Accessible markup (ARIA labels, semantic elements)
      - [ ] Mobile-first responsive design
      - [ ] Progressive enhancement (works without JS)

      ### New Stimulus Controller Checklist

      Creating a Stimulus controller? Follow this:

      - [ ] Name matches HTML (data-controller matches filename)
      - [ ] Use targets for DOM elements
      - [ ] Use values for configuration
      - [ ] Use actions for events
      - [ ] Keep controllers small and focused (single responsibility)
      - [ ] Clean up in disconnect() if needed
      - [ ] Use classes for CSS manipulation

      ---

      ## Topic Guides

      ### ⚡ Turbo (Hotwire)

      **Turbo Drive:**
      - Automatic page navigation without full reload
      - Enabled by default in Rails 7+
      - Use data-turbo="false" to disable on specific links/forms

      **Turbo Frames:**
      - Scoped page updates
      - Lazy loading support
      - Break out with data-turbo-frame="_top"

      **Turbo Streams:**
      - Real-time updates over WebSocket or HTTP
      - 7 actions: append, prepend, replace, update, remove, before, after
      - Format: respond_to with format.turbo_stream

      **[📖 Complete Guide: references/turbo_guide.md](references/turbo_guide.md)**

      ---

      ### 🎮 Stimulus Controllers

      **Stimulus = "Modest JavaScript Framework"**

      - Sprinkles JavaScript on server-rendered HTML
      - Three core concepts: Controllers, Actions, Targets
      - Lifecycle: connect() → disconnect()
      - Values for configuration (automatically typed)
      - Classes for CSS manipulation

      **[📖 Complete Guide: references/stimulus_guide.md](references/stimulus_guide.md)**

      ---

      ### 📚 Complete Examples

      **Full working examples:**

      - Modern view with Turbo Frames
      - Complete Stimulus controller
      - Form with real-time validation
      - Turbo Stream updates
      - Responsive layouts with Tailwind

      **[📖 Complete Guide: references/complete_examples.md](references/complete_examples.md)**

      ---

      ## Navigation Guide

      | Need to... | Read this resource |
      |------------|-------------------|
      | Use Turbo Frames/Streams   | [turbo_guide.md](references/turbo_guide.md) |
      | Create Stimulus controller | [stimulus_guide.md](references/stimulus_guide.md) |
      | See full examples          | [complete_examples.md](references/complete_examples.md) |

      ---

      ## Core Principles

      1. **Server-Side First**: Render HTML on server, enhance with JavaScript
      2. **Progressive Enhancement**: Works without JavaScript, better with it
      3. **Turbo for Navigation**: Use Turbo Drive/Frames instead of full page reloads
      4. **Stimulus for Interactivity**: Minimal JavaScript, attached to HTML
      5. **Tailwind for Styling**: Utility-first CSS in templates
      6. **Semantic HTML**: Use proper HTML5 elements
      7. **Partials for Reuse**: Extract common patterns to partials

      ---

      ## File Structure Quick Reference

      ```
      app/
        views/
          layouts/application.html.erb
          shared/_nav.html.erb
          posts/
            index.html.erb
            show.html.erb
            _post.html.erb
            _form.html.erb
        javascript/
          controllers/
            application.js
            hello_controller.js
            form_controller.js
      ```

      ---

      ## Related agents

      - **rails-backend-guidelines**: Backend patterns for controllers and models
      - **skill-developer**: For creating new agents

      ---

      **Skill Status**: Adapted for Rails 7+, Hotwire (Turbo + Stimulus), and Tailwind CSS
    '';
  };
in
{
  options.jvf.aiTools.agents."${agentName}" = {
    enable = (lib.mkEnableOption "Enable the ${agentFullName} skill") // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.opencode.agents."${agentName}" = agentOptions;
    jvf.programs.claudecode.agents."${agentName}" = agentOptions;
  };
}
