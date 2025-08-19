//SystemVerilog
///////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////
module pulse_width_clock_gate (
    input  wire clk_in,
    input  wire trigger,
    input  wire rst_n,
    input  wire [3:0] width,
    output wire clk_out
);
    // Pipeline stage 1 signals
    reg [3:0] width_stage1;
    reg trigger_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 signals
    reg [3:0] counter_stage2;
    reg enable_stage2;
    reg valid_stage2;
    
    // Internal pipeline signals
    wire [3:0] next_counter;
    wire next_enable;
    wire next_valid;
    
    // Pipeline stage 1 - Input Registration
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            width_stage1 <= 4'd0;
            trigger_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            width_stage1 <= width;
            trigger_stage1 <= trigger;
            valid_stage1 <= 1'b1;  // Always valid after reset
        end
    end
    
    // Combinational logic module for pipeline processing
    pulse_width_pipeline_logic pipeline_logic_inst (
        .trigger(trigger_stage1),
        .width(width_stage1),
        .counter(counter_stage2),
        .enable(enable_stage2),
        .valid_in(valid_stage1),
        .valid_stage2(valid_stage2),
        .next_counter(next_counter),
        .next_enable(next_enable),
        .next_valid(next_valid)
    );
    
    // Pipeline stage 2 - Processing and Output
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage2 <= 4'd0;
            enable_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            counter_stage2 <= next_counter;
            enable_stage2 <= next_enable;
            valid_stage2 <= next_valid;
        end
    end
    
    // Output gating with pipeline valid check
    assign clk_out = clk_in & enable_stage2 & valid_stage2;
    
endmodule

///////////////////////////////////////////////////////////
// Pipelined logic module
///////////////////////////////////////////////////////////
module pulse_width_pipeline_logic (
    input  wire trigger,
    input  wire [3:0] width,
    input  wire [3:0] counter,
    input  wire enable,
    input  wire valid_in,
    input  wire valid_stage2,
    output reg  [3:0] next_counter,
    output reg  next_enable,
    output reg  next_valid
);
    
    // Pipeline stage processing logic
    always @(*) begin
        // Default values
        next_counter = counter;
        next_enable = enable;
        next_valid = valid_stage2;
        
        if (valid_in) begin
            next_valid = 1'b1;
            
            if (trigger) begin
                next_counter = width;
                next_enable = 1'b1;
            end else if (|counter) begin
                next_counter = counter - 1'b1;
                next_enable = (counter > 4'd1) ? 1'b1 : 1'b0;
            end
        end
    end
    
endmodule