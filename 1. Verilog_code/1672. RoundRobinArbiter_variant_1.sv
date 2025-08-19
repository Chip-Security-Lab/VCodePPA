//SystemVerilog
module RoundRobinArbiter #(parameter WIDTH=4) (
    input clk, rst,
    input [WIDTH-1:0] req,
    output [WIDTH-1:0] grant,
    output valid
);

    wire [WIDTH-1:0] pointer_stage1;
    wire [WIDTH-1:0] req_stage1;
    wire valid_stage1;
    
    wire [WIDTH-1:0] pointer_stage2;
    wire [WIDTH-1:0] req_stage2;
    wire valid_stage2;
    
    wire [WIDTH-1:0] pointer_stage3;
    wire [WIDTH-1:0] grant_stage3;
    wire valid_stage3;

    Stage1 #(.WIDTH(WIDTH)) stage1_inst (
        .clk(clk),
        .rst(rst),
        .pointer_in(pointer_stage3),
        .req_in(req),
        .pointer_out(pointer_stage1),
        .req_out(req_stage1),
        .valid_out(valid_stage1)
    );

    Stage2 #(.WIDTH(WIDTH)) stage2_inst (
        .clk(clk),
        .rst(rst),
        .pointer_in(pointer_stage1),
        .req_in(req_stage1),
        .valid_in(valid_stage1),
        .pointer_out(pointer_stage2),
        .req_out(req_stage2),
        .valid_out(valid_stage2)
    );

    Stage3 #(.WIDTH(WIDTH)) stage3_inst (
        .clk(clk),
        .rst(rst),
        .pointer_in(pointer_stage2),
        .req_in(req_stage2),
        .valid_in(valid_stage2),
        .pointer_out(pointer_stage3),
        .grant_out(grant_stage3),
        .valid_out(valid_stage3)
    );

    OutputStage #(.WIDTH(WIDTH)) output_inst (
        .clk(clk),
        .rst(rst),
        .grant_in(grant_stage3),
        .valid_in(valid_stage3),
        .grant_out(grant),
        .valid_out(valid)
    );

endmodule

module Stage1 #(parameter WIDTH=4) (
    input clk, rst,
    input [WIDTH-1:0] pointer_in,
    input [WIDTH-1:0] req_in,
    output reg [WIDTH-1:0] pointer_out,
    output reg [WIDTH-1:0] req_out,
    output reg valid_out
);

    wire [WIDTH-1:0] rotated_pointer;
    assign rotated_pointer = {pointer_in[WIDTH-2:0], pointer_in[WIDTH-1]};

    always @(posedge clk) begin
        if (rst) begin
            pointer_out <= 0;
            req_out <= 0;
            valid_out <= 0;
        end else begin
            pointer_out <= rotated_pointer;
            req_out <= req_in;
            valid_out <= 1'b1;
        end
    end

endmodule

module Stage2 #(parameter WIDTH=4) (
    input clk, rst,
    input [WIDTH-1:0] pointer_in,
    input [WIDTH-1:0] req_in,
    input valid_in,
    output reg [WIDTH-1:0] pointer_out,
    output reg [WIDTH-1:0] req_out,
    output reg valid_out
);

    always @(posedge clk) begin
        if (rst) begin
            pointer_out <= 0;
            req_out <= 0;
            valid_out <= 0;
        end else begin
            pointer_out <= pointer_in;
            req_out <= req_in;
            valid_out <= valid_in;
        end
    end

endmodule

module Stage3 #(parameter WIDTH=4) (
    input clk, rst,
    input [WIDTH-1:0] pointer_in,
    input [WIDTH-1:0] req_in,
    input valid_in,
    output reg [WIDTH-1:0] pointer_out,
    output reg [WIDTH-1:0] grant_out,
    output reg valid_out
);

    wire [WIDTH-1:0] grant_pre;
    assign grant_pre = req_in & pointer_in;

    always @(posedge clk) begin
        if (rst) begin
            pointer_out <= 0;
            grant_out <= 0;
            valid_out <= 0;
        end else begin
            pointer_out <= pointer_in;
            grant_out <= grant_pre;
            valid_out <= valid_in;
        end
    end

endmodule

module OutputStage #(parameter WIDTH=4) (
    input clk, rst,
    input [WIDTH-1:0] grant_in,
    input valid_in,
    output reg [WIDTH-1:0] grant_out,
    output reg valid_out
);

    always @(posedge clk) begin
        if (rst) begin
            grant_out <= 0;
            valid_out <= 0;
        end else begin
            grant_out <= grant_in;
            valid_out <= valid_in;
        end
    end

endmodule