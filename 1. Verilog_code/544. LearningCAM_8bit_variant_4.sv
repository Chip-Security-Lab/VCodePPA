//SystemVerilog
module cam_4 (
    input wire clk,
    input wire rst,
    input wire write_en,
    input wire [7:0] write_data,
    input wire [7:0] read_data,
    output reg match_flag
);

    // Stage 1 signals
    reg [7:0] write_data_stage1;
    reg write_en_stage1;
    reg [7:0] read_data_stage1;
    
    // Stage 2 signals
    reg [7:0] data_a_stage2, data_b_stage2;
    reg [7:0] read_data_stage2;
    wire match_a_stage2, match_b_stage2;
    
    // Stage 3 signals
    reg match_a_stage3, match_b_stage3;

    // Stage 1: Input register
    always @(posedge clk) begin
        if (rst) begin
            write_data_stage1 <= 8'b0;
            write_en_stage1 <= 1'b0;
            read_data_stage1 <= 8'b0;
        end else begin
            write_data_stage1 <= write_data;
            write_en_stage1 <= write_en;
            read_data_stage1 <= read_data;
        end
    end

    // Stage 2: Data storage and comparison
    data_storage storage (
        .clk(clk),
        .rst(rst),
        .write_en(write_en_stage1),
        .write_data(write_data_stage1),
        .data_a(data_a_stage2),
        .data_b(data_b_stage2)
    );

    compare_logic compare (
        .data_a(data_a_stage2),
        .data_b(data_b_stage2),
        .read_data(read_data_stage1),
        .match_a(match_a_stage2),
        .match_b(match_b_stage2)
    );

    // Stage 2 to Stage 3 pipeline register
    always @(posedge clk) begin
        if (rst) begin
            match_a_stage3 <= 1'b0;
            match_b_stage3 <= 1'b0;
        end else begin
            match_a_stage3 <= match_a_stage2;
            match_b_stage3 <= match_b_stage2;
        end
    end

    // Stage 3: Match flag generation
    always @(posedge clk) begin
        if (rst) begin
            match_flag <= 1'b0;
        end else begin
            match_flag <= match_a_stage3 || match_b_stage3;
        end
    end

endmodule

module data_storage (
    input wire clk,
    input wire rst,
    input wire write_en,
    input wire [7:0] write_data,
    output reg [7:0] data_a,
    output reg [7:0] data_b
);

    always @(posedge clk) begin
        if (rst) begin
            data_a <= 8'b0;
            data_b <= 8'b0;
        end else if (write_en) begin
            data_a <= write_data;
            data_b <= write_data;
        end
    end

endmodule

module compare_logic (
    input wire [7:0] data_a,
    input wire [7:0] data_b,
    input wire [7:0] read_data,
    output wire match_a,
    output wire match_b
);

    assign match_a = (data_a == read_data);
    assign match_b = (data_b == read_data);

endmodule