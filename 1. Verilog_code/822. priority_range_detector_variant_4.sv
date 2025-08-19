//SystemVerilog
module priority_range_detector(
    input wire clk, rst_n,
    input wire [15:0] value,
    input wire [15:0] range_start [0:3],
    input wire [15:0] range_end [0:3],
    output reg [2:0] range_id,
    output reg valid
);
    reg [3:0] range_match;
    reg [1:0] match_priority;
    
    always @(*) begin
        range_match = 4'b0;
        for (integer i = 0; i < 4; i = i + 1) begin
            range_match[i] = (value >= range_start[i]) && (value <= range_end[i]);
        end
    end
    
    always @(*) begin
        match_priority = 2'b00;
        case(1'b1)
            range_match[0]: match_priority = 2'b00;
            range_match[1]: match_priority = 2'b01;
            range_match[2]: match_priority = 2'b10;
            range_match[3]: match_priority = 2'b11;
            default: match_priority = 2'b00;
        endcase
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            range_id <= 3'd0;
            valid <= 1'b0;
        end
        else begin
            range_id <= {1'b0, match_priority};
            valid <= |range_match;
        end
    end
endmodule