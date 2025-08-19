//SystemVerilog
module RingScheduler #(parameter BUF_SIZE=8) (
    input wire clk,
    input wire rst_n,
    input wire enable,
    output reg [BUF_SIZE-1:0] events,
    output reg valid_out
);

    // Move the computation logic before registers for retiming
    wire [2:0] next_ptr_stage1;
    wire valid_stage1_comb;
    wire [2:0] next_ptr_stage2;
    wire [BUF_SIZE-1:0] shifted_events;
    wire valid_stage2_comb;
    
    // Combinational logic moved before registers
    assign next_ptr_stage1 = enable ? (ptr_stage1 + 1) : ptr_stage1;
    assign valid_stage1_comb = enable;
    
    assign next_ptr_stage2 = ptr_stage1;
    assign shifted_events = (events_stage1 << 1) | (events_stage1[BUF_SIZE-1]);
    assign valid_stage2_comb = valid_stage1;
    
    // Pipeline stage 1 registers
    reg [2:0] ptr_stage1;
    reg [BUF_SIZE-1:0] events_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [2:0] ptr_stage2;
    reg [BUF_SIZE-1:0] events_stage2;
    reg valid_stage2;
    
    // Pipeline stage 1: Computation moved before register
    always @(posedge clk) begin
        if (!rst_n) begin
            ptr_stage1 <= 0;
            events_stage1 <= 1;
            valid_stage1 <= 0;
        end else begin
            ptr_stage1 <= next_ptr_stage1;
            events_stage1 <= events_stage1;
            valid_stage1 <= valid_stage1_comb;
        end
    end
    
    // Pipeline stage 2: Computation moved before register
    always @(posedge clk) begin
        if (!rst_n) begin
            ptr_stage2 <= 0;
            events_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            ptr_stage2 <= next_ptr_stage2;
            events_stage2 <= valid_stage1 ? shifted_events : events_stage2;
            valid_stage2 <= valid_stage2_comb;
        end
    end
    
    // Output stage
    always @(posedge clk) begin
        if (!rst_n) begin
            events <= 1;
            valid_out <= 0;
        end else begin
            events <= valid_stage2 ? events_stage2 : events;
            valid_out <= valid_stage2;
        end
    end

endmodule