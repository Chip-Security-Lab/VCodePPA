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
    reg [7:0] port1_data_buf, port2_data_buf;
    reg write_en_buf;
    
    // Data buffering
    always @(posedge clk) begin
        if (rst) begin
            port1_data_buf <= 8'b0;
            port2_data_buf <= 8'b0;
            write_en_buf <= 1'b0;
        end else begin
            port1_data_buf <= port1_data;
            port2_data_buf <= port2_data;
            write_en_buf <= write_en;
        end
    end
    
    // Storage update
    always @(posedge clk) begin
        if (rst) begin
            stored_port1 <= 8'b0;
            stored_port2 <= 8'b0;
        end else if (write_en_buf) begin
            stored_port1 <= port1_data_buf;
            stored_port2 <= port2_data_buf;
        end
    end
    
    // Match detection
    always @(posedge clk) begin
        if (rst) begin
            port1_match <= 1'b0;
            port2_match <= 1'b0;
        end else if (!write_en_buf) begin
            port1_match <= (stored_port1 == port1_data_buf);
            port2_match <= (stored_port2 == port2_data_buf);
        end
    end
endmodule