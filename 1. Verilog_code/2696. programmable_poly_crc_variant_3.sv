//SystemVerilog
module programmable_poly_crc(
    input wire clk,
    input wire rst,
    input wire [15:0] poly_in,
    input wire poly_load,
    input wire [7:0] data,
    input wire data_valid,
    output reg [15:0] crc
);
    reg [15:0] polynomial;
    reg [1:0] state;
    reg [15:0] next_crc;
    wire feedback;
    wire [15:0] feedback_value;
    wire [15:0] shifted_crc;
    
    // Explicit multiplexer structure for CRC computation
    assign feedback = crc[15] ^ data[0];
    assign feedback_value = feedback ? polynomial : 16'h0000;
    assign shifted_crc = {crc[14:0], 1'b0};
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= 2'b00;
            polynomial <= 16'h1021;
            crc <= 16'hFFFF;
        end else begin
            case(state)
                2'b00: begin  // Reset state
                    polynomial <= 16'h1021;
                    crc <= 16'hFFFF;
                    state <= 2'b01;
                end
                2'b01: begin  // Normal operation
                    if (poly_load) begin
                        polynomial <= poly_in;
                    end else if (data_valid) begin
                        crc <= shifted_crc ^ feedback_value;
                    end
                end
                default: state <= 2'b01;
            endcase
        end
    end
endmodule