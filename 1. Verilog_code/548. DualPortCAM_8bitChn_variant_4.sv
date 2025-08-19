//SystemVerilog
module cam_8 (
    input wire clk,
    input wire rst,
    input wire write_en,
    input wire [7:0] port1_data,
    input wire [7:0] port2_data,
    output reg port1_match,
    output reg port2_match
);
    reg [7:0] stored_port1, stored_port2;
    reg [1:0] state;
    reg [7:0] port1_data_buf, port2_data_buf;
    reg write_en_buf;
    
    // Buffer stage for high fanout signals
    always @(posedge clk) begin
        port1_data_buf <= port1_data;
        port2_data_buf <= port2_data;
        write_en_buf <= write_en;
    end
    
    always @(posedge clk) begin
        case(state)
            2'b00: begin  // Reset state
                stored_port1 <= 8'b0;
                stored_port2 <= 8'b0;
                port1_match <= 1'b0;
                port2_match <= 1'b0;
                state <= 2'b01;
            end
            2'b01: begin  // Write state
                if (write_en_buf) begin
                    stored_port1 <= port1_data_buf;
                    stored_port2 <= port2_data_buf;
                end
                state <= 2'b10;
            end
            2'b10: begin  // Compare state
                port1_match <= (stored_port1 == port1_data_buf);
                port2_match <= (stored_port2 == port2_data_buf);
                state <= 2'b01;
            end
            default: state <= 2'b00;
        endcase
    end
endmodule