//SystemVerilog
// Top-level module
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

    // Internal signals
    wire [DATA_WIDTH-1:0] reg_data_out;
    wire [2:0] current_level_out;
    
    // Register storage submodule
    ICMU_RegStorage #(
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_REGS(NUM_REGS)
    ) reg_storage (
        .clk(clk),
        .rst_async(rst_async),
        .int_level(int_level),
        .save_req(save_req),
        .context_bus(context_bus),
        .current_level(current_level_out),
        .reg_data_out(reg_data_out)
    );
    
    // Bus control submodule
    ICMU_BusControl #(
        .DATA_WIDTH(DATA_WIDTH)
    ) bus_control (
        .rst_async(rst_async),
        .restore_req(restore_req),
        .reg_data_in(reg_data_out),
        .current_level(current_level_out),
        .context_bus(context_bus)
    );

endmodule

// Register storage submodule
module ICMU_RegStorage #(
    parameter DATA_WIDTH = 64,
    parameter NUM_REGS = 8
)(
    input clk,
    input rst_async,
    input [2:0] int_level,
    input save_req,
    input [DATA_WIDTH-1:0] context_bus,
    output reg [2:0] current_level,
    output reg [DATA_WIDTH-1:0] reg_data_out
);

    reg [DATA_WIDTH-1:0] reg_group [0:NUM_REGS-1];
    
    always @(posedge clk or posedge rst_async) begin
        if (rst_async) begin
            current_level <= 0;
        end else if (save_req && (int_level < NUM_REGS)) begin
            reg_group[int_level] <= context_bus;
            current_level <= int_level;
        end
    end
    
    always @(*) begin
        reg_data_out = reg_group[current_level];
    end

endmodule

// Bus control submodule
module ICMU_BusControl #(
    parameter DATA_WIDTH = 64
)(
    input rst_async,
    input restore_req,
    input [DATA_WIDTH-1:0] reg_data_in,
    input [2:0] current_level,
    inout [DATA_WIDTH-1:0] context_bus
);

    reg [DATA_WIDTH-1:0] bus_out_reg;
    
    assign context_bus = restore_req && !rst_async ? bus_out_reg : {DATA_WIDTH{1'bz}};
    
    always @(*) begin
        if (restore_req && !rst_async)
            bus_out_reg = reg_data_in;
        else
            bus_out_reg = {DATA_WIDTH{1'bz}};
    end

endmodule