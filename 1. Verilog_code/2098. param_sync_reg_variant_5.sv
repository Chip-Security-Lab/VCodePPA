//SystemVerilog
module param_sync_reg #(
    parameter WIDTH=4
) (
    input                  clk1,
    input                  clk2,
    input                  rst,
    input  [WIDTH-1:0]     din,
    output reg [WIDTH-1:0] dout,
    output                 valid_out
);

    // Stage 1: Sample input on clk1
    reg [WIDTH-1:0] din_stage1;
    reg             valid_stage1;
    always @(posedge clk1 or posedge rst) begin
        if (rst) begin
            din_stage1   <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            din_stage1   <= din;
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 2: Synchronize data into clk2 domain (double register to help with CDC)
    reg [WIDTH-1:0] din_stage2;
    reg [WIDTH-1:0] din_stage3;
    reg             valid_stage2;
    reg             valid_stage3;
    always @(posedge clk2 or posedge rst) begin
        if (rst) begin
            din_stage2   <= {WIDTH{1'b0}};
            din_stage3   <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            din_stage2   <= din_stage1;
            din_stage3   <= din_stage2;
            valid_stage2 <= valid_stage1;
            valid_stage3 <= valid_stage2;
        end
    end

    // Stage 3: Output register on clk2 domain
    always @(posedge clk2 or posedge rst) begin
        if (rst) begin
            dout <= {WIDTH{1'b0}};
        end else if (valid_stage3) begin
            dout <= din_stage3;
        end
    end

    assign valid_out = valid_stage3;

endmodule