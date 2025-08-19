//SystemVerilog
module cam_5 (
    input wire clk,
    input wire rst,
    input wire write_en,
    input wire [15:0] input_data,
    output reg match,
    output reg [15:0] stored_data
);

    reg [15:0] input_data_stage1;
    reg write_en_stage1;
    reg [15:0] stored_data_stage1;
    reg [15:0] input_data_stage2;
    reg write_en_stage2;
    reg [15:0] stored_data_stage2;
    reg match_stage2;

    storage_unit_pipelined storage_inst (
        .clk(clk),
        .rst(rst),
        .write_en(write_en),
        .input_data(input_data),
        .stored_data(stored_data_stage1)
    );

    comparator_pipelined comp_inst (
        .clk(clk),
        .rst(rst),
        .write_en(write_en_stage2),
        .stored_data(stored_data_stage2),
        .input_data(input_data_stage2),
        .match(match)
    );

    always @(posedge clk) begin
        input_data_stage1 <= rst ? 16'b0 : input_data;
        write_en_stage1 <= rst ? 1'b0 : write_en;
    end

    always @(posedge clk) begin
        input_data_stage2 <= rst ? 16'b0 : input_data_stage1;
        write_en_stage2 <= rst ? 1'b0 : write_en_stage1;
        stored_data_stage2 <= rst ? 16'b0 : stored_data_stage1;
    end

endmodule

module storage_unit_pipelined (
    input wire clk,
    input wire rst,
    input wire write_en,
    input wire [15:0] input_data,
    output reg [15:0] stored_data
);

    reg [15:0] input_data_reg;
    reg write_en_reg;

    always @(posedge clk) begin
        input_data_reg <= rst ? 16'b0 : input_data;
        write_en_reg <= rst ? 1'b0 : write_en;
        stored_data <= rst ? 16'b0 : (write_en_reg ? input_data_reg : stored_data);
    end

endmodule

module comparator_pipelined (
    input wire clk,
    input wire rst,
    input wire write_en,
    input wire [15:0] stored_data,
    input wire [15:0] input_data,
    output reg match
);

    reg [15:0] stored_data_reg;
    reg [15:0] input_data_reg;
    reg write_en_reg;
    reg match_reg;

    always @(posedge clk) begin
        stored_data_reg <= rst ? 16'b0 : stored_data;
        input_data_reg <= rst ? 16'b0 : input_data;
        write_en_reg <= rst ? 1'b0 : write_en;
        match_reg <= rst ? 1'b0 : (!write_en_reg && (stored_data_reg == input_data_reg));
        match <= rst ? 1'b0 : match_reg;
    end

endmodule