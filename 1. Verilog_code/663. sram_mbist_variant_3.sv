//SystemVerilog
module sram_mbist #(
    parameter AW = 5,
    parameter DW = 8
)(
    input clk,
    input test_mode,
    output error_flag
);

// Memory array
reg [DW-1:0] mem [0:(1<<AW)-1];

// Test control registers
reg [AW:0] test_counter;
reg test_stage;
reg [AW-1:0] addr_reg;
reg [DW-1:0] data_reg;
reg error_reg;
reg error_reg_d;

// Test data generation
wire [DW-1:0] test_pattern = test_stage ? {DW{1'b1}} : {DW{1'b0}};

// Address generation pipeline
always @(posedge clk) begin
    if (test_mode) begin
        test_counter <= test_counter + 1;
        if (test_counter[AW]) begin
            test_stage <= ~test_stage;
        end
        addr_reg <= test_counter[AW-1:0];
    end
end

// Data write pipeline
always @(posedge clk) begin
    if (test_mode) begin
        mem[addr_reg] <= test_pattern;
        data_reg <= test_pattern;
    end
end

// Error detection pipeline with retiming
always @(posedge clk) begin
    if (test_mode) begin
        error_reg <= (mem[addr_reg] !== data_reg);
        error_reg_d <= error_reg;
    end else begin
        error_reg <= 1'b0;
        error_reg_d <= 1'b0;
    end
end

assign error_flag = error_reg_d;

endmodule