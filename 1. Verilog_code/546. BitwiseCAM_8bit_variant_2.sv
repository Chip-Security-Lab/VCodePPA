//SystemVerilog
// Pipeline stage 1 module
module cam_stage1 (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire write_en,
    output reg [7:0] data_out,
    output reg write_en_out
);
    always @(posedge clk) begin
        if (rst) begin
            data_out <= 8'b0;
            write_en_out <= 1'b0;
        end else begin
            data_out <= data_in;
            write_en_out <= write_en;
        end
    end
endmodule

// Pipeline stage 2 module
module cam_stage2 (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire write_en,
    output reg [7:0] stored_bits,
    output reg [7:0] data_out,
    output reg write_en_out
);
    always @(posedge clk) begin
        if (rst) begin
            stored_bits <= 8'b0;
            data_out <= 8'b0;
            write_en_out <= 1'b0;
        end else begin
            data_out <= data_in;
            write_en_out <= write_en;
            if (write_en) begin
                stored_bits <= data_in;
            end
        end
    end
endmodule

// Pipeline stage 3 module
module cam_stage3 (
    input wire clk,
    input wire rst,
    input wire [7:0] stored_bits,
    input wire [7:0] data_in,
    input wire write_en,
    output reg match_flag
);
    always @(posedge clk) begin
        if (rst) begin
            match_flag <= 1'b0;
        end else begin
            if (!write_en) begin
                match_flag <= (stored_bits == data_in);
            end
        end
    end
endmodule

// Top-level CAM module
module cam_6 (
    input wire clk,
    input wire rst,
    input wire write_en,
    input wire [7:0] data_in,
    output wire match_flag
);

    // Stage 1 signals
    wire [7:0] data_stage1;
    wire write_en_stage1;

    // Stage 2 signals
    wire [7:0] stored_bits_stage2;
    wire [7:0] data_stage2;
    wire write_en_stage2;

    // Stage 1 instance
    cam_stage1 stage1 (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .write_en(write_en),
        .data_out(data_stage1),
        .write_en_out(write_en_stage1)
    );

    // Stage 2 instance
    cam_stage2 stage2 (
        .clk(clk),
        .rst(rst),
        .data_in(data_stage1),
        .write_en(write_en_stage1),
        .stored_bits(stored_bits_stage2),
        .data_out(data_stage2),
        .write_en_out(write_en_stage2)
    );

    // Stage 3 instance
    cam_stage3 stage3 (
        .clk(clk),
        .rst(rst),
        .stored_bits(stored_bits_stage2),
        .data_in(data_stage2),
        .write_en(write_en_stage2),
        .match_flag(match_flag)
    );

endmodule