module width_reducer #(
    parameter IN_WIDTH = 32,
    parameter OUT_WIDTH = 8  // IN_WIDTH必须是OUT_WIDTH的整数倍
)(
    input wire clk, reset, in_valid,
    input wire [IN_WIDTH-1:0] data_in,
    output wire [OUT_WIDTH-1:0] data_out,
    output wire out_valid,
    output wire ready_for_input
);
    localparam RATIO = IN_WIDTH / OUT_WIDTH;
    localparam CNT_WIDTH = $clog2(RATIO);
    
    reg [IN_WIDTH-1:0] buffer;
    reg [CNT_WIDTH-1:0] count;
    reg out_valid_r, processing;
    
    always @(posedge clk) begin
        if (reset) begin
            count <= 0;
            buffer <= 0;
            out_valid_r <= 0;
            processing <= 0;
        end else if (in_valid && !processing) begin
            buffer <= data_in;
            count <= 0;
            out_valid_r <= 1;
            processing <= 1;
        end else if (processing) begin
            if (count < RATIO-1) begin
                count <= count + 1;
                buffer <= buffer >> OUT_WIDTH;
            end else begin
                processing <= 0;
                out_valid_r <= 0;
            end
        end
    end
    
    assign data_out = buffer[OUT_WIDTH-1:0];
    assign out_valid = out_valid_r;
    assign ready_for_input = !processing;
endmodule