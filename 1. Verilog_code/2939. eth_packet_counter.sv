module eth_packet_counter #(parameter COUNTER_WIDTH = 32) (
    input wire clk,
    input wire reset_n,
    input wire packet_valid,
    input wire packet_error,
    output reg [COUNTER_WIDTH-1:0] good_packets,
    output reg [COUNTER_WIDTH-1:0] error_packets,
    output reg [COUNTER_WIDTH-1:0] total_packets
);
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            good_packets <= {COUNTER_WIDTH{1'b0}};
            error_packets <= {COUNTER_WIDTH{1'b0}};
            total_packets <= {COUNTER_WIDTH{1'b0}};
        end else begin
            if (packet_valid) begin
                total_packets <= total_packets + 1'b1;
                if (!packet_error)
                    good_packets <= good_packets + 1'b1;
                else
                    error_packets <= error_packets + 1'b1;
            end
        end
    end
endmodule