module priority_range_detector(
    input wire clk, rst_n,
    input wire [15:0] value,
    input wire [15:0] range_start [0:3],
    input wire [15:0] range_end [0:3],
    output reg [2:0] range_id,
    output reg valid
);
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin range_id <= 3'd0; valid <= 1'b0; end
        else begin
            valid <= 1'b0;
            for (i = 0; i < 4; i = i + 1) begin
                if (!valid && (value >= range_start[i]) && (value <= range_end[i])) begin
                    range_id <= i;
                    valid <= 1'b1;
                end
            end
        end
    end
endmodule