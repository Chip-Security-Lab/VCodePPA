module eth_frame_sync #(
    parameter IN_WIDTH = 8,
    parameter OUT_WIDTH = 32
)(
    input clk,
    input rst,
    input [IN_WIDTH-1:0] data_in,
    input in_valid,
    output reg [OUT_WIDTH-1:0] data_out,
    output reg out_valid,
    output reg sof,
    output reg eof
);
    localparam RATIO = OUT_WIDTH / IN_WIDTH;
    reg [IN_WIDTH*RATIO-1:0] shift_reg;
    reg [3:0] count;
    reg prev_sof;

    always @(posedge clk) begin
        if (rst) begin
            shift_reg <= 0;
            count <= 0;
            out_valid <= 0;
            sof <= 0;
            eof <= 0;
            prev_sof <= 0;
        end else begin
            if (in_valid) begin
                shift_reg <= {shift_reg[IN_WIDTH*(RATIO-1)-1:0], data_in};
                count <= count + 1;
                
                if (data_in === 8'hD5 && !prev_sof) begin
                    sof <= 1;
                    prev_sof <= 1;
                    count <= 0;
                end else begin
                    sof <= 0;
                    prev_sof <= prev_sof;
                end

                if (count === RATIO-1) begin
                    data_out <= shift_reg;
                    out_valid <= 1;
                    count <= 0;
                    eof <= (shift_reg[IN_WIDTH*RATIO-1 -: 8] === 8'hFD);
                end else begin
                    out_valid <= 0;
                    eof <= 0;
                end
            end else begin
                out_valid <= 0;
                sof <= 0;
                eof <= 0;
            end
        end
    end
endmodule
