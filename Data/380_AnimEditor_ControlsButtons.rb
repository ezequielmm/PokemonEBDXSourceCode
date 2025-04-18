module BattleAnimationEditor
  #=============================================================================
  #
  #=============================================================================
  module ShadowText
    def shadowtext(bitmap, x, y, w, h, t, disabled = false, align = 0)
      width = bitmap.text_size(t).width
      case align
      when 2
        x += (w - width)
      when 1
        x += (w / 2) - (width / 2)
      end
      pbDrawShadowText(bitmap, x, y + 6, w, h, t,
                       disabled ? Color.new(208, 208, 200) : Color.new(96, 96, 96),
                       Color.new(208, 208, 200))
    end
  end

  #=============================================================================
  #
  #=============================================================================
  class UIControl
    include ShadowText
    attr_accessor :bitmap
    attr_accessor :label
    attr_accessor :x
    attr_accessor :y
    attr_accessor :width
    attr_accessor :height
    attr_accessor :changed
    attr_accessor :parent
    attr_accessor :disabled

    def text
      return self.label
    end

    def text=(value)
      self.label = value
    end

    def initialize(label)
      @label = label
      @x = 0
      @y = 0
      @width = 0
      @height = 0
      @changed = false
      @disabled = false
      @invalid = true
    end

    def toAbsoluteRect(rc)
      return Rect.new(rc.x + self.parentX, rc.y + self.parentY, rc.width, rc.height)
    end

    def parentX
      return 0 if !self.parent
      return self.parent.x + self.parent.leftEdge if self.parent.is_a?(SpriteWindow)
      return self.parent.x + 16 if self.parent.is_a?(Window)
      return self.parent.x
    end

    def parentY
      return 0 if !self.parent
      return self.parent.y + self.parent.topEdge if self.parent.is_a?(SpriteWindow)
      return self.parent.y + 16 if self.parent.is_a?(Window)
      return self.parent.y
    end

    def invalid?
      return @invalid
    end

    # Marks that the control must be redrawn to reflect current logic.
    def invalidate
      @invalid = true
    end

    # Updates the logic on the control, invalidating it if necessary.
    def update; end

    # Redraws the control.
    def refresh; end

    # Makes the control no longer invalid.
    def validate
      @invalid = false
    end

    # Redraws the control only if it is invalid.
    def repaint
      return if !self.invalid?
      self.refresh
      self.validate
    end
  end

  #=============================================================================
  #
  #=============================================================================
  class Label < UIControl
    def text=(value)
      self.label = value
      refresh
    end

    def refresh
      bitmap = self.bitmap
      bitmap.fill_rect(self.x, self.y, self.width, self.height, Color.new(0, 0, 0, 0))
      size = bitmap.text_size(self.label).width
      shadowtext(bitmap, self.x + 4, self.y, size, self.height, self.label, @disabled)
    end
  end

  #=============================================================================
  #
  #=============================================================================
  class Button < UIControl
    attr_accessor :label

    def initialize(label)
      super
      @captured = false
      @label = label
    end

    def update
      mousepos = Mouse.getMousePos
      self.changed = false
      return if !mousepos
      rect = Rect.new(self.x + 1, self.y + 1, self.width - 2, self.height - 2)
      rect = toAbsoluteRect(rect)
      if Input.trigger?(Input::MOUSELEFT) &&
         rect.contains?(mousepos[0], mousepos[1]) && !@captured
        @captured = true
        self.invalidate
      end
      if Input.release?(Input::MOUSELEFT) && @captured
        self.changed = true if rect.contains?(mousepos[0], mousepos[1])
        @captured = false
        self.invalidate
      end
    end

    def refresh
      bitmap = self.bitmap
      x = self.x
      y = self.y
      width = self.width
      height = self.height
      # Draw background
      if @captured
        bitmap.fill_rect(x + 2, y + 2, width - 4, height - 4, Color.new(120, 120, 120, 80))
      else
        bitmap.fill_rect(x + 2, y + 2, width - 4, height - 4, Color.new(0, 0, 0, 0))
      end
      # Draw text
      size = bitmap.text_size(self.label).width
      shadowtext(bitmap, x + 4, y, size, height, self.label, @disabled)
      # Draw outline
      color = Color.new(120, 120, 120)
      bitmap.fill_rect(x + 1, y + 1, width - 2, 1, color)
      bitmap.fill_rect(x + 1, y + 1, 1, height - 2, color)
      bitmap.fill_rect(x + 1, y + height - 2, width - 2, 1, color)
      bitmap.fill_rect(x + width - 2, y + 1, 1, height - 2, color)
      # Return the control's clickable area
      ret = Rect.new(x + 1, y + 1, width - 2, height - 2)
      return ret
    end
  end

  #=============================================================================
  #
  #=============================================================================
  class Checkbox < Button
    attr_reader :checked

    def curvalue
      return self.checked
    end

    def curvalue=(value)
      self.checked = value
    end

    def checked=(value)
      @checked = value
      invalidate
    end

    def initialize(label)
      super
      @checked = false
    end

    def update
      super
      if self.changed
        @checked = !@checked
        self.invalidate
      end
    end

    def refresh
      bitmap = self.bitmap
      x = self.x
      y = self.y
      width = [self.width, 32].min
      height = [self.height, 32].min
      # Draw background
      bitmap.fill_rect(x + 2, y + 2, self.width - 4, self.height - 4, Color.new(0, 0, 0, 0))
      if @captured
        bitmap.fill_rect(x + 2, y + 2, width - 4, height - 4, Color.new(120, 120, 120, 80))
      else
        bitmap.fill_rect(x + 2, y + 2, width - 4, height - 4, Color.new(0, 0, 0, 0))
      end
      # Draw text
      shadowtext(bitmap, x, y, 32, 32, "X", @disabled, 1) if self.checked
      size = bitmap.text_size(self.label).width
      shadowtext(bitmap, x + 36, y, size, height, self.label, @disabled)
      # Draw outline
      color = Color.new(120, 120, 120)
      bitmap.fill_rect(x + 1, y + 1, width - 2, 1, color)
      bitmap.fill_rect(x + 1, y + 1, 1, height - 2, color)
      bitmap.fill_rect(x + 1, y + height - 2, width - 2, 1, color)
      bitmap.fill_rect(x + width - 2, y + 1, 1, height - 2, color)
      # Return the control's clickable area
      ret = Rect.new(x + 1, y + 1, width - 2, height - 2)
      return ret
    end
  end

  #=============================================================================
  #
  #=============================================================================
  class TextField < UIControl
    attr_accessor :label
    attr_reader :text

    def text=(value)
      @text = value
      @cursor_shown = true
      self.invalidate
    end

    def initialize(label, text)
      super(label)
      @cursor_timer_start = System.uptime
      @cursor_shown = true
      @label = label
      @text = text
      @cursor = text.scan(/./m).length
    end

    def insert(ch)
      chars = self.text.scan(/./m)
      chars.insert(@cursor, ch)
      @text = ""
      chars.each { |char| @text += char }
      @cursor += 1
      @cursor_timer_start = System.uptime
      @cursor_shown = true
      self.changed = true
      self.invalidate
    end

    def delete
      chars = self.text.scan(/./m)
      chars.delete_at(@cursor - 1)
      @text = ""
      chars.each { |char| @text += char }
      @cursor -= 1
      @cursor_timer_start = System.uptime
      @cursor_shown = true
      self.changed = true
      self.invalidate
    end

    def update
      cursor_to_show = ((System.uptime - @cursor_timer_start) / 0.35).to_i.even?
      self.changed = false
      if cursor_to_show != @cursor_shown
        @cursor_shown = cursor_to_show
        self.invalidate
      end
      # Moving cursor
      if Input.triggerex?(:LEFT) || Input.repeatex?(:LEFT)
        if @cursor > 0
          @cursor -= 1
          @cursor_timer_start = System.uptime
          @cursor_shown = true
          self.invalidate
        end
        return
      end
      if Input.triggerex?(:RIGHT) || Input.repeatex?(:RIGHT)
        if @cursor < self.text.scan(/./m).length
          @cursor += 1
          @cursor_timer_start = System.uptime
          @cursor_shown = true
          self.invalidate
        end
        return
      end
      # Backspace
      if Input.triggerex?(:BACKSPACE) || Input.repeatex?(:BACKSPACE) ||
         Input.triggerex?(:DELETE) || Input.repeatex?(:DELETE)
        self.delete if @cursor > 0
        return
      end
      # Letter & Number keys
      Input.gets.each_char { |c| insert(c) }
    end

    def refresh
      bitmap = self.bitmap
      x = self.x
      y = self.y
      width = self.width
      height = self.height
      color = Color.new(120, 120, 120)
      bitmap.font.color = color
      bitmap.fill_rect(x, y, width, height, Color.new(0, 0, 0, 0))
      size = bitmap.text_size(self.label).width
      shadowtext(bitmap, x, y, size, height, self.label)
      x += size
      width -= size
      outline_x = x
      outline_y = y
      # Draw background
      if @captured
        bitmap.fill_rect(x + 2, y + 2, width - 4, height - 4, Color.new(120, 120, 120, 80))
      else
        bitmap.fill_rect(x + 2, y + 2, width - 4, height - 4, Color.new(0, 0, 0, 0))
      end
      # Draw text
      x += 4
      textscan = self.text.scan(/./m)
      scanlength = textscan.length
      @cursor = scanlength if @cursor > scanlength
      @cursor = 0 if @cursor < 0
      startpos = @cursor
      fromcursor = 0
      while startpos > 0
        c = textscan[startpos - 1]
        fromcursor += bitmap.text_size(c).width
        break if fromcursor > width - 4
        startpos -= 1
      end
      (startpos...scanlength).each do |i|
        c = textscan[i]
        textwidth = bitmap.text_size(c).width
        next if c == "\n"
        # Draw text
        shadowtext(bitmap, x, y, textwidth + 4, 32, c)
        # Draw cursor if necessary
        if i == @cursor && @cursor_shown
          bitmap.fill_rect(x, y + 4, 2, 24, Color.new(120, 120, 120))
        end
        # Add x to drawn text width
        x += textwidth
      end
      if textscan.length == @cursor && @cursor_shown
        bitmap.fill_rect(x, y + 4, 2, 24, Color.new(120, 120, 120))
      end
      # Draw outline
      bitmap.fill_rect(outline_x + 1, outline_y + 1, width - 2, 1, color)
      bitmap.fill_rect(outline_x + 1, outline_y + 1, 1, height - 2, color)
      bitmap.fill_rect(outline_x + 1, outline_y + height - 2, width - 2, 1, color)
      bitmap.fill_rect(outline_x + width - 2, outline_y + 1, 1, height - 2, color)
      # Return the control's clickable area
      ret = Rect.new(x + 1, y + 1, width - 2, height - 2)
      return ret
    end
  end

  #=============================================================================
  #
  #=============================================================================
  class Slider < UIControl
    attr_reader :minvalue
    attr_reader :maxvalue
    attr_reader :curvalue
    attr_accessor :label

    def curvalue=(value)
      @curvalue = value
      @curvalue = self.minvalue if self.minvalue && @curvalue < self.minvalue
      @curvalue = self.maxvalue if self.maxvalue && @curvalue > self.maxvalue
      self.invalidate
    end

    def minvalue=(value)
      @minvalue = value
      @curvalue = self.minvalue if self.minvalue && @curvalue < self.minvalue
      @curvalue = self.maxvalue if self.maxvalue && @curvalue > self.maxvalue
      self.invalidate
    end

    def maxvalue=(value)
      @maxvalue = value
      @curvalue = self.minvalue if self.minvalue && @curvalue < self.minvalue
      @curvalue = self.maxvalue if self.maxvalue && @curvalue > self.maxvalue
      self.invalidate
    end

    def initialize(label, minvalue, maxvalue, curval)
      super(label)
      @minvalue = minvalue
      @maxvalue = maxvalue
      @curvalue = curval
      @label = label
      @leftarrow = Rect.new(0, 0, 0, 0)
      @rightarrow = Rect.new(0, 0, 0, 0)
      self.minvalue = minvalue
      self.maxvalue = maxvalue
      self.curvalue = curval
    end

    def update
      mousepos = Mouse.getMousePos
      self.changed = false
      if self.minvalue < self.maxvalue && self.curvalue < self.minvalue
        self.curvalue = self.minvalue
      end
      return false if self.disabled
      return false if !Input.repeat?(Input::MOUSELEFT)
      return false if !mousepos
      left = toAbsoluteRect(@leftarrow)
      right = toAbsoluteRect(@rightarrow)
      oldvalue = self.curvalue
      repeattime = Input.time?(Input::MOUSELEFT)
      # Left arrow
      if left.contains?(mousepos[0], mousepos[1])
        if repeattime > 3.0
          self.curvalue -= 10
        elsif repeattime > 1.5
          self.curvalue -= 5
        else
          self.curvalue -= 1
        end
        self.curvalue = self.curvalue.floor
        self.changed = (self.curvalue != oldvalue)
        self.invalidate
      end
      # Right arrow
      if right.contains?(mousepos[0], mousepos[1])
        if repeattime > 3.0
          self.curvalue += 10
        elsif repeattime > 1.5
          self.curvalue += 5
        else
          self.curvalue += 1
        end
        self.curvalue = self.curvalue.floor
        self.changed = (self.curvalue != oldvalue)
        self.invalidate
      end
    end

    def refresh
      bitmap = self.bitmap
      x = self.x
      y = self.y
      width = self.width
      height = self.height
      color = Color.new(120, 120, 120)
      bitmap.fill_rect(x, y, width, height, Color.new(0, 0, 0, 0))
      size = bitmap.text_size(self.label).width
      leftarrows = bitmap.text_size(" <<")
      numbers = bitmap.text_size(" XXXX ").width
      rightarrows = bitmap.text_size(">> ")
      bitmap.font.color = color
      shadowtext(bitmap, x, y, size, height, self.label)
      x += size
      shadowtext(bitmap, x, y, leftarrows.width, height, " <<",
                 self.disabled || self.curvalue == self.minvalue)
      @leftarrow = Rect.new(x, y, leftarrows.width, height)
      x += leftarrows.width
      if !self.disabled
        bitmap.font.color = color
        shadowtext(bitmap, x, y, numbers, height, " #{self.curvalue} ", false, 1)
      end
      x += numbers
      shadowtext(bitmap, x, y, rightarrows.width, height, ">> ",
                 self.disabled || self.curvalue == self.maxvalue)
      @rightarrow = Rect.new(x, y, rightarrows.width, height)
    end
  end

  #=============================================================================
  #
  #=============================================================================
  class OptionalSlider < Slider
    def initialize(label, minvalue, maxvalue, curvalue)
      @slider = Slider.new(label, minvalue, maxvalue, curvalue)
      @checkbox = Checkbox.new("")
    end

    def curvalue
      return @checkbox.checked ? @slider.curvalue : nil
    end

    def curvalue=(value)
      slider.curvalue = value
    end

    def checked
      return @checkbox.checked
    end

    def checked=(value)
      @checkbox.checked = value
    end

    def invalid?
      return @slider.invalid? || @checkbox.invalid?
    end

    def invalidate
      @slider.invalidate
      @checkbox.invalidate
    end

    def validate?
      @slider.validate
      @checkbox.validate
    end

    def changed
      return @slider.changed || @checkbox.changed
    end

    def minvalue
      return @slider.minvalue
    end

    def minvalue=(value)
      slider.minvalue = value
    end

    def maxvalue
      return @slider.maxvalue
    end

    def maxvalue=(value)
      slider.maxvalue = value
    end

    def update
      updatedefs
      @slider.update
      @checkbox.update
    end

    def refresh
      updatedefs
      @slider.refresh
      @checkbox.refresh
    end

    #---------------------------------------------------------------------------

    private

    def updatedefs
      checkboxwidth = 32
      @slider.bitmap = self.bitmap
      @slider.parent = self.parent
      @checkbox.x = self.x
      @checkbox.y = self.y
      @checkbox.width = checkboxwidth
      @checkbox.height = self.height
      @checkbox.bitmap = self.bitmap
      @checkbox.parent = self.parent
      @slider.x = self.x + checkboxwidth + 4
      @slider.y = self.y
      @slider.width = self.width - checkboxwidth
      @slider.height = self.height
      @slider.disabled = !@checkbox.checked
    end
  end

  #=============================================================================
  #
  #=============================================================================
  class ArrayCountSlider < Slider
    def maxvalue
      return @array.length - 1
    end

    def initialize(array, label)
      @array = array
      super(label, 0, canvas.animation.length - 1, 0)
    end
  end

  #=============================================================================
  #
  #=============================================================================
  class FrameCountSlider < Slider
    def maxvalue
      return @canvas.animation.length
    end

    def initialize(canvas)
      @canvas = canvas
      super(_INTL("Frame:"), 1, canvas.animation.length, 0)
    end
  end

  #=============================================================================
  #
  #=============================================================================
  class FrameCountButton < Button
    def label
      return _INTL("Total Frames: {1}", @canvas.animation.length)
    end

    def initialize(canvas)
      @canvas = canvas
      super(self.label)
    end
  end

  #=============================================================================
  #
  #=============================================================================
  class TextSlider < UIControl
    attr_reader :minvalue
    attr_reader :maxvalue
    attr_reader :curvalue
    attr_accessor :label
    attr_accessor :options
    attr_accessor :maxoptionwidth

    def curvalue=(value)
      @curvalue = value
      @curvalue = self.minvalue if self.minvalue && @curvalue < self.minvalue
      @curvalue = self.maxvalue if self.maxvalue && @curvalue > self.maxvalue
      self.invalidate
    end

    def minvalue=(value)
      @minvalue = value
      @curvalue = self.minvalue if self.minvalue && @curvalue < self.minvalue
      @curvalue = self.maxvalue if self.maxvalue && @curvalue > self.maxvalue
      self.invalidate
    end

    def maxvalue=(value)
      @maxvalue = value
      @curvalue = self.minvalue if self.minvalue && @curvalue < self.minvalue
      @curvalue = self.maxvalue if self.maxvalue && @curvalue > self.maxvalue
      self.invalidate
    end

    def initialize(label, options, curval)
      super(label)
      @label = label
      @options = options
      @minvalue = 0
      @maxvalue = options.length - 1
      @curvalue = curval
      @leftarrow = Rect.new(0, 0, 0, 0)
      @rightarrow = Rect.new(0, 0, 0, 0)
      self.minvalue = @minvalue
      self.maxvalue = @maxvalue
      self.curvalue = @curvalue
    end

    def update
      mousepos = Mouse.getMousePos
      self.changed = false
      if self.minvalue < self.maxvalue && self.curvalue < self.minvalue
        self.curvalue = self.minvalue
      end
      return false if self.disabled
      return false if !Input.repeat?(Input::MOUSELEFT)
      return false if !mousepos
      left = toAbsoluteRect(@leftarrow)
      right = toAbsoluteRect(@rightarrow)
      oldvalue = self.curvalue
      repeattime = Input.time?(Input::MOUSELEFT)
      # Left arrow
      if left.contains?(mousepos[0], mousepos[1])
        if repeattime > 3.0
          self.curvalue -= 10
        elsif repeattime > 1.5
          self.curvalue -= 5
        else
          self.curvalue -= 1
        end
        self.changed = (self.curvalue != oldvalue)
        self.invalidate
      end
      # Right arrow
      if right.contains?(mousepos[0], mousepos[1])
        if repeattime > 3.0
          self.curvalue += 10
        elsif repeattime > 1.5
          self.curvalue += 5
        else
          self.curvalue += 1
        end
        self.changed = (self.curvalue != oldvalue)
        self.invalidate
      end
    end

    def refresh
      bitmap = self.bitmap
      if @maxoptionwidth.nil?
        @options.length.times do |i|
          w = self.bitmap.text_size(" " + @options[i] + " ").width
          @maxoptionwidth = w if !@maxoptionwidth || @maxoptionwidth < w
        end
      end
      x = self.x
      y = self.y
      width = self.width
      height = self.height
      color = Color.new(120, 120, 120)
      bitmap.fill_rect(x, y, width, height, Color.new(0, 0, 0, 0))
      size = bitmap.text_size(self.label).width
      leftarrows = bitmap.text_size(" <<")
      rightarrows = bitmap.text_size(">> ")
      bitmap.font.color = color
      shadowtext(bitmap, x, y, size, height, self.label)
      x += size
      shadowtext(bitmap, x, y, leftarrows.width, height, " <<",
                 self.disabled || self.curvalue == self.minvalue)
      @leftarrow = Rect.new(x, y, leftarrows.width, height)
      x += leftarrows.width
      if !self.disabled
        bitmap.font.color = color
        shadowtext(bitmap, x, y, @maxoptionwidth, height, " #{@options[self.curvalue]} ", false, 1)
      end
      x += @maxoptionwidth
      shadowtext(bitmap, x, y, rightarrows.width, height, ">> ",
                 self.disabled || self.curvalue == self.maxvalue)
      @rightarrow = Rect.new(x, y, rightarrows.width, height)
    end
  end

  #=============================================================================
  #
  #=============================================================================
  class OptionalTextSlider < TextSlider
    def initialize(label, options, curval)
      @slider = TextSlider.new(label, options, curval)
      @checkbox = Checkbox.new("")
    end

    def curvalue
      return @checkbox.checked ? @slider.curvalue : nil
    end

    def curvalue=(value)
      slider.curvalue = value
    end

    def checked
      return @checkbox.checked
    end

    def checked=(value)
      @checkbox.checked = value
    end

    def invalid?
      return @slider.invalid? || @checkbox.invalid?
    end

    def invalidate
      @slider.invalidate
      @checkbox.invalidate
    end

    def validate?
      @slider.validate
      @checkbox.validate
    end

    def changed
      return @slider.changed || @checkbox.changed
    end

    def minvalue
      return @slider.minvalue
    end

    def minvalue=(value)
      slider.minvalue = value
    end

    def maxvalue
      return @slider.maxvalue
    end

    def maxvalue=(value)
      slider.maxvalue = value
    end

    def update
      updatedefs
      @slider.update
      @checkbox.update
    end

    def refresh
      updatedefs
      @slider.refresh
      @checkbox.refresh
    end

    #---------------------------------------------------------------------------

    private

    def updatedefs
      checkboxwidth = 32
      @slider.bitmap = self.bitmap
      @slider.parent = self.parent
      @checkbox.x = self.x
      @checkbox.y = self.y
      @checkbox.width = checkboxwidth
      @checkbox.height = self.height
      @checkbox.bitmap = self.bitmap
      @checkbox.parent = self.parent
      @slider.x = self.x + checkboxwidth + 4
      @slider.y = self.y
      @slider.width = self.width - checkboxwidth
      @slider.height = self.height
      @slider.disabled = !@checkbox.checked
    end
  end

  #=============================================================================
  #
  #=============================================================================
  class ControlWindow < SpriteWindow_Base
    attr_reader :controls

    def initialize(x, y, width, height)
      super(x, y, width, height)
      self.contents = Bitmap.new(width - 32, height - 32)
      pbSetNarrowFont(self.contents)
      @controls = []
    end

    def dispose
      self.contents.dispose
      super
    end

    def refresh
      @controls.each { |ctrl| ctrl.refresh }
    end

    def repaint
      @controls.each { |ctrl| ctrl.repaint }
    end

    def invalidate
      @controls.each { |ctrl| ctrl.invalidate }
    end

    def hittest?(i)
      mousepos = Mouse.getMousePos
      return false if !mousepos
      return false if i < 0 || i >= @controls.length
      rc = Rect.new(@controls[i].parentX, @controls[i].parentY,
                    @controls[i].width, @controls[i].height)
      return rc.contains?(mousepos[0], mousepos[1])
    end

    def addControl(control)
      i = @controls.length
      @controls[i] = control
      @controls[i].x = 0
      @controls[i].y = i * 32
      @controls[i].width = self.contents.width
      @controls[i].height = 32
      @controls[i].parent = self
      @controls[i].bitmap = self.contents
      @controls[i].invalidate
      refresh
      return i
    end

    def addLabel(label)
      return addControl(Label.new(label))
    end

    def addButton(label)
      return addControl(Button.new(label))
    end

    def addSlider(label, minvalue, maxvalue, curvalue)
      return addControl(Slider.new(label, minvalue, maxvalue, curvalue))
    end

    def addOptionalSlider(label, minvalue, maxvalue, curvalue)
      return addControl(OptionalSlider.new(label, minvalue, maxvalue, curvalue))
    end

    def addTextSlider(label, options, curvalue)
      return addControl(TextSlider.new(label, options, curvalue))
    end

    def addOptionalTextSlider(label, options, curvalue)
      return addControl(OptionalTextSlider.new(label, options, curvalue))
    end

    def addCheckbox(label)
      return addControl(Checkbox.new(label))
    end

    def addSpace
      return addControl(UIControl.new(""))
    end

    def update
      super
      @controls.each { |ctrl| ctrl.update }
      repaint
    end

    def changed?(i)
      return false if i < 0
      return @controls[i].changed
    end

    def value(i)
      return false if i < 0
      return @controls[i].curvalue
    end
  end
end
