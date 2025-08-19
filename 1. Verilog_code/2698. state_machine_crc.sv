module state_machine_crc(
    input wire clk,
    input wire rst,
    input wire start,
    input wire [7:0] data,
    output reg [15:0] crc_out,
    output reg crc_ready
);
    parameter [15:0] POLY = 16'h1021;
    parameter IDLE = 2'b00, PROCESS = 2'b01, FINALIZE = 2'b10;
    reg [1:0] state, next_state;
    reg [3:0] bit_count;
    
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            crc_out <= 16'hFFFF;
            bit_count <= 4'd0;
            crc_ready <= 1'b0;
        end else begin
            case (state)
                IDLE: if (start) state <= PROCESS;
                PROCESS: begin
                    crc_out <= {crc_out[14:0], 1'b0} ^ 
                             ((crc_out[15] ^ data[bit_count]) ? POLY : 16'h0);
                    bit_count <= bit_count + 1;
                    if (bit_count == 4'd7) state <= FINALIZE;
                end
                FINALIZE: begin
                    crc_ready <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule