//SystemVerilog
module keypad_scanner(
    input wire clk, rst_n,
    input wire [3:0] rows,
    output reg [3:0] cols,
    output reg [3:0] key_value,
    output reg key_valid,
    input wire key_ready
);

    localparam IDLE = 2'b00;
    localparam SCAN = 2'b01;
    localparam DEBOUNCE = 2'b10;
    localparam OUTPUT = 2'b11;

    reg [1:0] state, next_state;
    reg [3:0] col_counter;
    reg [7:0] debounce_counter;
    reg [3:0] row_buffer;
    reg [3:0] key_value_reg;
    reg [3:0] col_pattern;
    reg [3:0] next_col_pattern;
    reg [3:0] key_value_next;
    reg key_valid_next;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            col_pattern <= 4'b1110;
            col_counter <= 4'd0;
            debounce_counter <= 8'd0;
            key_value <= 4'd0;
            key_valid <= 1'b0;
            row_buffer <= 4'b1111;
        end else begin
            state <= next_state;
            row_buffer <= rows;
            col_pattern <= next_col_pattern;
            if (key_ready || !key_valid) begin
                key_value <= key_value_next;
                key_valid <= key_valid_next;
            end
        end
    end

    always @(*) begin
        key_value_next = key_value;
        key_valid_next = key_valid;
        next_col_pattern = col_pattern;
        
        case (state)
            IDLE: begin
                key_valid_next = 1'b0;
                col_counter = 4'd0;
                next_col_pattern = 4'b1110;
            end
            
            SCAN: begin
                if (row_buffer != 4'b1111) begin
                    debounce_counter = 8'd0;
                end else begin
                    next_col_pattern = {col_pattern[0], col_pattern[3:1]};
                    col_counter = col_counter + 4'd1;
                end
            end
            
            DEBOUNCE: begin
                if (debounce_counter == 8'd255 && row_buffer != 4'b1111) begin
                    key_value_next = decode_key(col_counter, row_buffer);
                end
            end
            
            OUTPUT: begin
                if (!key_valid || key_ready) begin
                    key_valid_next = 1'b1;
                end
            end
        endcase
    end

    always @(*) begin
        case (state)
            IDLE: next_state = SCAN;
            SCAN: next_state = (row_buffer != 4'b1111) ? DEBOUNCE : 
                             (col_counter == 4'd3) ? IDLE : SCAN;
            DEBOUNCE: next_state = (debounce_counter == 8'd255 && row_buffer != 4'b1111) ? 
                                 OUTPUT : DEBOUNCE;
            OUTPUT: next_state = (key_valid && key_ready) ? IDLE : OUTPUT;
            default: next_state = IDLE;
        endcase
    end

    function [3:0] decode_key;
        input [3:0] col;
        input [3:0] row;
        begin
            case ({col, row})
                {4'd0, 4'b1110}: decode_key = 4'h1;
                {4'd0, 4'b1101}: decode_key = 4'h4;
                {4'd0, 4'b1011}: decode_key = 4'h7;
                {4'd0, 4'b0111}: decode_key = 4'hE;
                {4'd1, 4'b1110}: decode_key = 4'h2;
                {4'd1, 4'b1101}: decode_key = 4'h5;
                {4'd1, 4'b1011}: decode_key = 4'h8;
                {4'd1, 4'b0111}: decode_key = 4'h0;
                {4'd2, 4'b1110}: decode_key = 4'h3;
                {4'd2, 4'b1101}: decode_key = 4'h6;
                {4'd2, 4'b1011}: decode_key = 4'h9;
                {4'd2, 4'b0111}: decode_key = 4'hF;
                {4'd3, 4'b1110}: decode_key = 4'hA;
                {4'd3, 4'b1101}: decode_key = 4'hB;
                {4'd3, 4'b1011}: decode_key = 4'hC;
                {4'd3, 4'b0111}: decode_key = 4'hD;
                default: decode_key = 4'h0;
            endcase
        end
    endfunction

    assign cols = col_pattern;

endmodule