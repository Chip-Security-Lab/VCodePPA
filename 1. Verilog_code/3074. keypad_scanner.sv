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
    
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            state <= IDLE;
            cols <= 4'b0000;
            col_cnt <= 4'd0;
            debounce_cnt <= 8'd0;
            key_value <= 4'd0;
            key_valid <= 1'b0;
        end else begin
            state <= next;
            row_reg <= rows;
            
            case (state)
                IDLE: begin
                    key_valid <= 1'b0;
                    col_cnt <= 4'd0;
                    cols <= 4'b1110; // Start with first column
                end
                SCAN: begin
                    if (row_reg != 4'b1111) begin
                        // Key pressed
                        debounce_cnt <= 8'd0;
                    end else begin
                        // Move to next column
                        cols <= {cols[0], cols[3:1]};
                        col_cnt <= col_cnt + 4'd1;
                    end
                end
                DEBOUNCE: begin
                    debounce_cnt <= debounce_cnt + 8'd1;
                    if (debounce_cnt == 8'd255 && row_reg != 4'b1111) begin
                        // Generate key value based on row and column
                        case ({col_cnt, row_reg})
                            {4'd0, 4'b1110}: key_value <= 4'h1;
                            {4'd0, 4'b1101}: key_value <= 4'h4;
                            {4'd0, 4'b1011}: key_value <= 4'h7;
                            {4'd0, 4'b0111}: key_value <= 4'hE; // *
                            {4'd1, 4'b1110}: key_value <= 4'h2;
                            {4'd1, 4'b1101}: key_value <= 4'h5;
                            {4'd1, 4'b1011}: key_value <= 4'h8;
                            {4'd1, 4'b0111}: key_value <= 4'h0;
                            {4'd2, 4'b1110}: key_value <= 4'h3;
                            {4'd2, 4'b1101}: key_value <= 4'h6;
                            {4'd2, 4'b1011}: key_value <= 4'h9;
                            {4'd2, 4'b0111}: key_value <= 4'hF; // #
                            {4'd3, 4'b1110}: key_value <= 4'hA; // A
                            {4'd3, 4'b1101}: key_value <= 4'hB; // B
                            {4'd3, 4'b1011}: key_value <= 4'hC; // C
                            {4'd3, 4'b0111}: key_value <= 4'hD; // D
                            default: key_value <= 4'h0;
                        endcase
                    end
                end
                OUTPUT: key_valid <= 1'b1;
            endcase
        end
    
    always @(*)
        case (state)
            IDLE: next = SCAN;
            SCAN: next = (row_reg != 4'b1111) ? DEBOUNCE : 
                        (col_cnt == 4'd3) ? IDLE : SCAN;
            DEBOUNCE: next = (debounce_cnt == 8'd255 && row_reg != 4'b1111) ? 
                            OUTPUT : DEBOUNCE;
            OUTPUT: next = IDLE;
            default: next = IDLE;
        endcase
endmodule
