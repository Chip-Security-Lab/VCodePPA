module i2c_multi_addr_slave(
    input wire clk, rst,
    input wire [6:0] primary_addr, secondary_addr,
    output reg [7:0] rx_data,
    output reg rx_valid,
    inout wire sda, scl
);
    reg sda_dir, sda_out;
    reg [2:0] state;
    reg [7:0] shift_reg;
    reg [3:0] bit_idx;
    reg addr_matched;
    reg start_detected; // Added missing signal
    
    assign sda = sda_dir ? sda_out : 1'bz;
    
    // Start condition detection
    reg scl_prev, sda_prev;
    always @(posedge clk) begin
        scl_prev <= scl;
        sda_prev <= sda;
        start_detected <= scl && scl_prev && !sda && sda_prev;
    end
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= 3'b000;
            rx_valid <= 1'b0;
            sda_dir <= 1'b0;
            sda_out <= 1'b0;
            bit_idx <= 4'b0000;
            addr_matched <= 1'b0;
        end else case (state)
            3'b000: if (start_detected) begin
                state <= 3'b001;
                bit_idx <= 4'b0000;
                shift_reg <= 8'h00;
            end
            3'b001: if (bit_idx == 4'd7) begin
                addr_matched <= (shift_reg[7:1] == primary_addr) || 
                               (shift_reg[7:1] == secondary_addr);
                state <= addr_matched ? 3'b010 : 3'b000;
                sda_dir <= addr_matched; // Pull SDA low for ACK if address matched
                sda_out <= 1'b0;
            end else if (scl) begin
                shift_reg <= {shift_reg[6:0], sda};
                bit_idx <= bit_idx + 1;
            end
            3'b010: begin
                // After ACK, prepare for data reception
                state <= 3'b011;
                bit_idx <= 4'b0000;
                sda_dir <= 1'b0; // Release SDA
            end
            3'b011: if (bit_idx == 4'd7) begin
                rx_data <= shift_reg;
                rx_valid <= 1'b1;
                state <= 3'b000;
            end else if (scl) begin
                shift_reg <= {shift_reg[6:0], sda};
                bit_idx <= bit_idx + 1;
            end
            default: state <= 3'b000;
        endcase
    end
endmodule