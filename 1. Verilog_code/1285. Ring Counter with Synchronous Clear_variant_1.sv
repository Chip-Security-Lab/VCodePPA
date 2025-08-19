//SystemVerilog
module clear_ring_counter (
    input  wire       clk,
    input  wire       clear,   // Synchronous clear
    input  wire       valid_in, // Input valid signal for pipeline
    output wire       valid_out, // Output valid signal
    output wire [3:0] counter
);
    // Pipeline stage registers
    reg [3:0] counter_stage1;
    reg [3:0] counter_stage2;
    reg [3:0] counter_stage3;
    
    // Pipeline valid signals
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Stage 1: Counter update logic
    reg [3:0] next_counter;
    
    always @(*) begin
        if (clear)
            next_counter = 4'b0000;
        else if (counter_stage1 == 4'b0000)
            next_counter = 4'b0001;
        else
            next_counter = {counter_stage1[2:0], counter_stage1[3]};
    end
    
    // Pipeline stage 1 registers
    always @(posedge clk) begin
        counter_stage1 <= (valid_in) ? next_counter : counter_stage1;
        valid_stage1 <= valid_in;
    end
    
    // Pipeline stage 2 registers
    always @(posedge clk) begin
        counter_stage2 <= counter_stage1;
        valid_stage2 <= valid_stage1;
    end
    
    // Pipeline stage 3 registers
    always @(posedge clk) begin
        counter_stage3 <= counter_stage2;
        valid_stage3 <= valid_stage2;
    end
    
    // Output assignment
    assign counter = counter_stage2 & counter_stage3; // Distribute load between stages
    assign valid_out = valid_stage3;
    
    // Initialization
    initial begin
        counter_stage1 = 4'b0001;
        counter_stage2 = 4'b0001;
        counter_stage3 = 4'b0001;
        valid_stage1 = 1'b0;
        valid_stage2 = 1'b0;
        valid_stage3 = 1'b0;
    end
endmodule