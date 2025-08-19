//SystemVerilog
module ICMU_AsyncRegGroup #(
    parameter DATA_WIDTH = 64,
    parameter NUM_REGS = 8
)(
    input clk,
    input rst_async,
    input [2:0] int_level,
    input save_req,
    input restore_req,
    inout [DATA_WIDTH-1:0] context_bus
);
    reg [DATA_WIDTH-1:0] reg_group [0:NUM_REGS-1];
    reg [2:0] current_level;
    reg [DATA_WIDTH-1:0] bus_out;
    reg [NUM_REGS-1:0] level_match;
    
    // Optimized level match generation using a single always block
    always @* begin
        level_match = {NUM_REGS{1'b0}};
        if (int_level < NUM_REGS) begin
            level_match[int_level] = 1'b1;
        end
    end
    
    // Optimized bus output logic
    always @* begin
        bus_out = {DATA_WIDTH{1'bz}};
        if (restore_req && !rst_async && current_level < NUM_REGS) begin
            bus_out = reg_group[current_level];
        end
    end
    
    // Direct bus assignment
    assign context_bus = restore_req && !rst_async ? bus_out : {DATA_WIDTH{1'bz}};
    
    // Optimized save logic
    always @(posedge save_req or posedge rst_async) begin
        if (rst_async) begin
            current_level <= 0;
        end else if (save_req && int_level < NUM_REGS) begin
            reg_group[int_level] <= context_bus;
            current_level <= int_level;
        end
    end
endmodule