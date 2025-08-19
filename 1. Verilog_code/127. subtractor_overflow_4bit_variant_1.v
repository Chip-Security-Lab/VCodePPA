// Pipeline stage 1: Input register and sign extension
module input_stage (
    input clk,
    input rst_n,
    input [3:0] a_in,
    input [3:0] b_in,
    output reg [4:0] a_ext,
    output reg [4:0] b_ext
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_ext <= 5'b0;
            b_ext <= 5'b0;
        end else begin
            a_ext <= {a_in[3], a_in};
            b_ext <= {b_in[3], b_in};
        end
    end
endmodule

// Pipeline stage 2: Subtraction core
module subtraction_core (
    input clk,
    input rst_n,
    input [4:0] a_ext,
    input [4:0] b_ext,
    output reg [4:0] diff_ext
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff_ext <= 5'b0;
        end else begin
            diff_ext <= a_ext - b_ext;
        end
    end
endmodule

// Pipeline stage 3: Overflow detection and output
module output_stage (
    input clk,
    input rst_n,
    input [4:0] diff_ext,
    output reg [3:0] diff,
    output reg overflow
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff <= 4'b0;
            overflow <= 1'b0;
        end else begin
            diff <= diff_ext[3:0];
            overflow <= (diff_ext[4] ^ diff_ext[3]) & (diff_ext[4] ^ diff_ext[3]);
        end
    end
endmodule

// Top-level pipelined subtractor
module subtractor_overflow_4bit_pipelined (
    input clk,
    input rst_n,
    input [3:0] a,
    input [3:0] b,
    output [3:0] diff,
    output overflow
);
    // Pipeline stage signals
    wire [4:0] a_ext, b_ext;
    wire [4:0] diff_ext;
    
    // Instantiate pipeline stages
    input_stage input_stage_inst (
        .clk(clk),
        .rst_n(rst_n),
        .a_in(a),
        .b_in(b),
        .a_ext(a_ext),
        .b_ext(b_ext)
    );
    
    subtraction_core sub_core_inst (
        .clk(clk),
        .rst_n(rst_n),
        .a_ext(a_ext),
        .b_ext(b_ext),
        .diff_ext(diff_ext)
    );
    
    output_stage output_stage_inst (
        .clk(clk),
        .rst_n(rst_n),
        .diff_ext(diff_ext),
        .diff(diff),
        .overflow(overflow)
    );
endmodule