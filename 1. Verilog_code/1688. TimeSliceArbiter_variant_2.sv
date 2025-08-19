//SystemVerilog
module TimeSliceArbiter #(
    parameter SLICE_WIDTH = 8
) (
    input  wire                     clk,
    input  wire                     rst,
    input  wire [3:0]              req,
    output reg  [3:0]              grant
);

    reg [SLICE_WIDTH-1:0]          counter_r;
    reg [3:0]                      req_decoded_r;
    wire [1:0]                     counter_lsb = counter_r[1:0];
    wire [3:0]                     req_mask = 4'b0001 << counter_lsb;
    
    // 优化计数器逻辑
    always @(posedge clk) begin
        if (rst) begin
            counter_r <= 'd0;
        end else begin
            counter_r <= (counter_r == 'd4) ? 'd0 : (counter_r + 'd1);
        end
    end
    
    // 优化请求解码逻辑
    always @(posedge clk) begin
        if (rst) begin
            req_decoded_r <= 'd0;
        end else begin
            req_decoded_r <= req & req_mask;
        end
    end
    
    // 优化授权输出逻辑
    always @(posedge clk) begin
        if (rst) begin
            grant <= 'd0;
        end else begin
            grant <= req_decoded_r;
        end
    end

endmodule