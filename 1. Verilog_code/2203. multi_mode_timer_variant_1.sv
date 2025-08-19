//SystemVerilog
module multi_mode_timer #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst,
    input wire [1:0] mode,
    input wire [WIDTH-1:0] period,
    output reg out,
    // Pipeline control signals
    input wire valid_in,
    output reg valid_out,
    input wire ready_in,
    output wire ready_out
);
    // Pipeline stage 1 - Input and counter management
    reg [WIDTH-1:0] counter_stage1;
    reg [WIDTH-1:0] period_stage1;
    reg [1:0] mode_stage1;
    reg valid_stage1;
    wire period_reached_stage1;
    wire half_period_reached_stage1;
    
    // Pipeline stage 2 - Mode decoding and comparisons
    reg [WIDTH-1:0] counter_stage2;
    reg [WIDTH-1:0] period_stage2;
    reg [1:0] mode_stage2;
    reg valid_stage2;
    reg period_reached_stage2;
    reg half_period_reached_stage2;
    reg is_oneshot_mode_stage2;
    reg is_periodic_mode_stage2;
    reg is_pwm_mode_stage2;
    reg is_toggle_mode_stage2;
    
    // Pipeline stage 3 - Output generation
    reg out_next;
    reg out_stage3;
    reg valid_stage3;
    
    // Stage 1 comparison logic
    assign period_reached_stage1 = (counter_stage1 >= period_stage1 - 1'b1);
    assign half_period_reached_stage1 = (counter_stage1 < (period_stage1 >> 1));
    
    // Pipeline control
    assign ready_out = 1'b1; // Always ready to accept new inputs in this implementation
    
    // Pipeline stage 1: Input registration and counter management
    always @(posedge clk) begin
        if (rst) begin
            counter_stage1 <= {WIDTH{1'b0}};
            period_stage1 <= {WIDTH{1'b0}};
            mode_stage1 <= 2'b00;
            valid_stage1 <= 1'b0;
        end else if (ready_out && valid_in) begin
            // Register inputs
            period_stage1 <= period;
            mode_stage1 <= mode;
            valid_stage1 <= 1'b1;
            
            // Counter management
            if (period_reached_stage1 && (mode_stage1 == 2'd1 || mode_stage1 == 2'd2 || mode_stage1 == 2'd3)) begin
                counter_stage1 <= {WIDTH{1'b0}};
            end else if (mode_stage1 == 2'd0 && counter_stage1 >= period_stage1) begin
                counter_stage1 <= counter_stage1; // Hold counter in one-shot mode after period
            end else begin
                counter_stage1 <= counter_stage1 + 1'b1;
            end
        end else if (!valid_stage1 || (valid_stage1 && valid_stage2)) begin
            // Continue counting when pipeline is moving
            if (period_reached_stage1 && (mode_stage1 == 2'd1 || mode_stage1 == 2'd2 || mode_stage1 == 2'd3)) begin
                counter_stage1 <= {WIDTH{1'b0}};
            end else if (mode_stage1 == 2'd0 && counter_stage1 >= period_stage1) begin
                counter_stage1 <= counter_stage1; // Hold counter in one-shot mode after period
            end else begin
                counter_stage1 <= counter_stage1 + 1'b1;
            end
        end
    end
    
    // Pipeline stage 2: Mode decoding and comparison registration
    always @(posedge clk) begin
        if (rst) begin
            counter_stage2 <= {WIDTH{1'b0}};
            period_stage2 <= {WIDTH{1'b0}};
            mode_stage2 <= 2'b00;
            period_reached_stage2 <= 1'b0;
            half_period_reached_stage2 <= 1'b0;
            is_oneshot_mode_stage2 <= 1'b0;
            is_periodic_mode_stage2 <= 1'b0;
            is_pwm_mode_stage2 <= 1'b0;
            is_toggle_mode_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1 && (!valid_stage2 || valid_stage3)) begin
            // Pass data from stage 1 to stage 2
            counter_stage2 <= counter_stage1;
            period_stage2 <= period_stage1;
            mode_stage2 <= mode_stage1;
            period_reached_stage2 <= period_reached_stage1;
            half_period_reached_stage2 <= half_period_reached_stage1;
            valid_stage2 <= valid_stage1;
            
            // Mode decoder - one-hot encoding
            is_oneshot_mode_stage2 <= (mode_stage1 == 2'd0);
            is_periodic_mode_stage2 <= (mode_stage1 == 2'd1);
            is_pwm_mode_stage2 <= (mode_stage1 == 2'd2);
            is_toggle_mode_stage2 <= (mode_stage1 == 2'd3);
        end
    end
    
    // Pipeline stage 3: Output generation
    always @(posedge clk) begin
        if (rst) begin
            out_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else if (valid_stage2 && (!valid_stage3 || ready_in)) begin
            // Generate output based on mode
            valid_stage3 <= valid_stage2;
            
            case (1'b1) // Synthesizes as parallel logic
                is_oneshot_mode_stage2: out_stage3 <= (counter_stage2 < period_stage2) ? 1'b1 : 1'b0;
                is_periodic_mode_stage2: out_stage3 <= period_reached_stage2 ? 1'b1 : 1'b0;
                is_pwm_mode_stage2: out_stage3 <= half_period_reached_stage2;
                is_toggle_mode_stage2: begin
                    if (period_reached_stage2) begin
                        out_stage3 <= ~out_stage3;
                    end
                end
                default: out_stage3 <= 1'b0;
            endcase
        end
    end
    
    // Final output stage
    always @(posedge clk) begin
        if (rst) begin
            out <= 1'b0;
            valid_out <= 1'b0;
        end else if (valid_stage3 && ready_in) begin
            out <= out_stage3;
            valid_out <= valid_stage3;
        end
    end
endmodule