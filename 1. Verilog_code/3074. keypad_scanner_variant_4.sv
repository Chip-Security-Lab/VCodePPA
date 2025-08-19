//SystemVerilog
module keypad_scanner(
    input wire clk, rst_n,
    input wire [3:0] rows,
    output reg [3:0] cols,
    output reg [3:0] key_value,
    output reg key_valid
);
    localparam IDLE=2'b00, SCAN=2'b01, DEBOUNCE=2'b10, OUTPUT=2'b11;
    reg [1:0] state, next;
    reg [3:0] col_cnt;
    reg [7:0] debounce_cnt;
    reg [3:0] row_reg;
    reg [3:0] next_cols;
    reg [3:0] next_key_value;
    reg next_key_valid;
    reg [3:0] col_row_combined;
    
    // Pre-compute column-row combination
    assign col_row_combined = {col_cnt, row_reg};
    
    // Next state logic
    always @(*) begin
        case (state)
            IDLE: next = SCAN;
            SCAN: next = (row_reg != 4'b1111) ? DEBOUNCE : 
                        (col_cnt == 4'd3) ? IDLE : SCAN;
            DEBOUNCE: next = (debounce_cnt == 8'd255 && row_reg != 4'b1111) ? 
                            OUTPUT : DEBOUNCE;
            OUTPUT: next = IDLE;
            default: next = IDLE;
        endcase
    end
    
    // Output and state update logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            cols <= 4'b0000;
            col_cnt <= 4'd0;
            debounce_cnt <= 8'd0;
            key_value <= 4'd0;
            key_valid <= 1'b0;
            row_reg <= 4'b1111;
        end else begin
            state <= next;
            row_reg <= rows;
            
            // Pre-compute next column value
            next_cols = (state == IDLE) ? 4'b1110 : 
                       (state == SCAN && row_reg == 4'b1111) ? {cols[0], cols[3:1]} : cols;
            
            // Pre-compute key value
            if (state == DEBOUNCE && debounce_cnt == 8'd255 && row_reg != 4'b1111) begin
                case (col_row_combined)
                    8'b0000_1110: next_key_value = 4'h1;
                    8'b0000_1101: next_key_value = 4'h4;
                    8'b0000_1011: next_key_value = 4'h7;
                    8'b0000_0111: next_key_value = 4'hE;
                    8'b0001_1110: next_key_value = 4'h2;
                    8'b0001_1101: next_key_value = 4'h5;
                    8'b0001_1011: next_key_value = 4'h8;
                    8'b0001_0111: next_key_value = 4'h0;
                    8'b0010_1110: next_key_value = 4'h3;
                    8'b0010_1101: next_key_value = 4'h6;
                    8'b0010_1011: next_key_value = 4'h9;
                    8'b0010_0111: next_key_value = 4'hF;
                    8'b0011_1110: next_key_value = 4'hA;
                    8'b0011_1101: next_key_value = 4'hB;
                    8'b0011_1011: next_key_value = 4'hC;
                    8'b0011_0111: next_key_value = 4'hD;
                    default: next_key_value = 4'h0;
                endcase
            end else begin
                next_key_value = key_value;
            end
            
            // Update registers
            cols <= next_cols;
            col_cnt <= (state == IDLE) ? 4'd0 : 
                      (state == SCAN && row_reg == 4'b1111) ? col_cnt + 4'd1 : col_cnt;
            debounce_cnt <= (state == SCAN && row_reg != 4'b1111) ? 8'd0 :
                           (state == DEBOUNCE) ? debounce_cnt + 8'd1 : debounce_cnt;
            key_value <= next_key_value;
            key_valid <= (state == OUTPUT) ? 1'b1 : 1'b0;
        end
    end
endmodule