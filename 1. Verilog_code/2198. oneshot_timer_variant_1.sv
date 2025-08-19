//SystemVerilog
/*
 * Top-level module for oneshot timer with pipelined architecture
 * IEEE 1364-2005 Verilog standard
 */
module oneshot_timer (
    input  wire        clock,
    input  wire        reset,
    input  wire        trigger,
    input  wire [15:0] duration,
    output wire        pulse_out
);
    // Clock and reset buffering
    wire        clk_buf1, clk_buf2, clk_buf3;
    wire        rst_buf1, rst_buf2, rst_buf3;
    
    // Clock tree buffers
    assign clk_buf1 = clock;
    assign clk_buf2 = clock;
    assign clk_buf3 = clock;
    
    // Reset tree buffers
    assign rst_buf1 = reset;
    assign rst_buf2 = reset;
    assign rst_buf3 = reset;
    
    // Input signal buffers
    wire        trigger_buf;
    wire [15:0] duration_buf;
    
    assign trigger_buf = trigger;
    assign duration_buf = duration;

    // Internal connection signals
    wire        trigger_edge_detected;
    wire        trigger_edge_detected_buf1, trigger_edge_detected_buf2;
    wire [15:0] latched_duration;
    wire [15:0] latched_duration_buf;
    wire        active_counter;
    wire        active_counter_buf;
    wire [15:0] counter_value;
    wire [15:0] counter_value_buf;
    wire        pulse_out_internal;
    wire        pulse_out_internal_buf;

    // Buffer high fanout signals
    assign trigger_edge_detected_buf1 = trigger_edge_detected;
    assign trigger_edge_detected_buf2 = trigger_edge_detected;
    assign latched_duration_buf = latched_duration;
    assign active_counter_buf = active_counter;
    assign counter_value_buf = counter_value;
    assign pulse_out_internal_buf = pulse_out_internal;

    // Edge detector module instance
    edge_detector u_edge_detector (
        .clock                (clk_buf1),
        .reset                (rst_buf1),
        .trigger              (trigger_buf),
        .duration_in          (duration_buf),
        .trigger_edge_detected(trigger_edge_detected),
        .latched_duration     (latched_duration)
    );

    // Counter manager module instance
    counter_manager u_counter_manager (
        .clock                (clk_buf2),
        .reset                (rst_buf2),
        .trigger_edge_detected(trigger_edge_detected_buf1),
        .duration             (latched_duration_buf),
        .active               (active_counter),
        .count                (counter_value),
        .pulse_out            (pulse_out_internal)
    );

    // Output stage module instance
    output_stage u_output_stage (
        .clock                (clk_buf3),
        .reset                (rst_buf3),
        .active_in            (active_counter_buf),
        .count_in             (counter_value_buf),
        .duration_in          (latched_duration_buf),
        .pulse_out_in         (pulse_out_internal_buf),
        .pulse_out            (pulse_out)
    );
endmodule

/*
 * Edge detector module - Pipeline stage 1
 * Detects rising edge on trigger input and latches duration
 */
module edge_detector (
    input  wire        clock,
    input  wire        reset,
    input  wire        trigger,
    input  wire [15:0] duration_in,
    output reg         trigger_edge_detected,
    output reg  [15:0] latched_duration
);
    reg prev_trigger;
    wire trigger_int;
    reg [15:0] duration_reg;
    
    // Buffer input signals to reduce load
    assign trigger_int = trigger;

    always @(posedge clock) begin
        if (reset) begin
            duration_reg <= 16'd0;
        end else begin
            duration_reg <= duration_in;
        end
    end

    always @(posedge clock) begin
        if (reset) begin
            prev_trigger <= 1'b0;
            trigger_edge_detected <= 1'b0;
            latched_duration <= 16'd0;
        end else begin
            prev_trigger <= trigger_int;
            trigger_edge_detected <= !prev_trigger && trigger_int;
            latched_duration <= duration_reg;
        end
    end
endmodule

/*
 * Counter manager module - Pipeline stage 2
 * Manages the timer counter and initial pulse generation
 */
module counter_manager (
    input  wire        clock,
    input  wire        reset,
    input  wire        trigger_edge_detected,
    input  wire [15:0] duration,
    output reg         active,
    output reg  [15:0] count,
    output reg         pulse_out
);
    reg trigger_edge_detected_reg;
    reg [15:0] duration_reg;
    
    // Buffer high-fanout duration signal
    always @(posedge clock) begin
        if (reset) begin
            duration_reg <= 16'd0;
        end else begin
            duration_reg <= duration;
        end
    end

    always @(posedge clock) begin
        if (reset) begin
            active <= 1'b0;
            count <= 16'd0;
            pulse_out <= 1'b0;
            trigger_edge_detected_reg <= 1'b0;
        end else begin
            trigger_edge_detected_reg <= trigger_edge_detected;
            
            if (trigger_edge_detected_reg) begin
                active <= 1'b1;
                count <= 16'd0;
                pulse_out <= 1'b1;
            end else if (active) begin
                if (count >= duration_reg - 1) begin
                    active <= 1'b0;
                    pulse_out <= 1'b0;
                end else begin
                    count <= count + 1'b1;
                end
            end
        end
    end
endmodule

/*
 * Output stage module - Pipeline stage 3
 * Buffers the outputs for improved timing
 */
module output_stage (
    input  wire        clock,
    input  wire        reset,
    input  wire        active_in,
    input  wire [15:0] count_in,
    input  wire [15:0] duration_in,
    input  wire        pulse_out_in,
    output reg         pulse_out
);
    reg active;
    reg [15:0] count;
    reg [15:0] duration;
    reg pulse_out_stage1;

    // Split high fanout output into two stages to reduce delay
    always @(posedge clock) begin
        if (reset) begin
            active <= 1'b0;
            count <= 16'd0;
            duration <= 16'd0;
            pulse_out_stage1 <= 1'b0;
        end else begin
            active <= active_in;
            count <= count_in;
            duration <= duration_in;
            pulse_out_stage1 <= pulse_out_in;
        end
    end
    
    // Second stage for pulse output to distribute load
    always @(posedge clock) begin
        if (reset) begin
            pulse_out <= 1'b0;
        end else begin
            pulse_out <= pulse_out_stage1;
        end
    end
endmodule