//SystemVerilog
module keypad_scanner(
    input wire clk, rst_n,
    input wire [3:0] rows,
    output reg [3:0] cols,
    output reg [3:0] key_value,
    output reg key_valid
);

    localparam IDLE=2'b00, SCAN=2'b01, DEBOUNCE=2'b10, OUTPUT=2'b11;
    
    // Stage 1 registers
    reg [1:0] state_stage1, next_stage1;
    reg [3:0] col_cnt_stage1;
    reg [3:0] row_reg_stage1;
    reg [3:0] cols_stage1;
    
    // Stage 2 registers
    reg [1:0] state_stage2;
    reg [3:0] col_cnt_stage2;
    reg [3:0] row_reg_stage2;
    reg [3:0] cols_stage2;
    reg [7:0] debounce_cnt_stage2;
    reg key_pressed_stage2;
    
    // Stage 3 registers
    reg [1:0] state_stage3;
    reg [3:0] key_value_stage3;
    reg key_valid_stage3;
    
    // Stage 1: Row sampling and column scanning
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1 <= IDLE;
            cols_stage1 <= 4'b0000;
            col_cnt_stage1 <= 4'd0;
            row_reg_stage1 <= 4'b1111;
        end else begin
            state_stage1 <= next_stage1;
            row_reg_stage1 <= rows;
            
            case (state_stage1)
                IDLE: begin
                    col_cnt_stage1 <= 4'd0;
                    cols_stage1 <= 4'b1110;
                end
                SCAN: begin
                    if (row_reg_stage1 == 4'b1111) begin
                        cols_stage1 <= {cols_stage1[0], cols_stage1[3:1]};
                        col_cnt_stage1 <= col_cnt_stage1 + 4'd1;
                    end
                end
                default: begin
                    cols_stage1 <= cols_stage1;
                    col_cnt_stage1 <= col_cnt_stage1;
                end
            endcase
        end
    end
    
    // Stage 2: Debounce and key value calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage2 <= IDLE;
            debounce_cnt_stage2 <= 8'd0;
            key_pressed_stage2 <= 1'b0;
            col_cnt_stage2 <= 4'd0;
            row_reg_stage2 <= 4'b1111;
            cols_stage2 <= 4'b0000;
        end else begin
            state_stage2 <= state_stage1;
            col_cnt_stage2 <= col_cnt_stage1;
            row_reg_stage2 <= row_reg_stage1;
            cols_stage2 <= cols_stage1;
            
            if (state_stage2 == DEBOUNCE) begin
                debounce_cnt_stage2 <= debounce_cnt_stage2 + 8'd1;
                key_pressed_stage2 <= (row_reg_stage2 != 4'b1111);
            end else begin
                debounce_cnt_stage2 <= 8'd0;
                key_pressed_stage2 <= 1'b0;
            end
        end
    end
    
    // Stage 3: Key value output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage3 <= IDLE;
            key_value_stage3 <= 4'd0;
            key_valid_stage3 <= 1'b0;
        end else begin
            state_stage3 <= state_stage2;
            
            if (state_stage3 == OUTPUT) begin
                key_valid_stage3 <= 1'b1;
                case ({col_cnt_stage2, row_reg_stage2})
                    {4'd0, 4'b1110}: key_value_stage3 <= 4'h1;
                    {4'd0, 4'b1101}: key_value_stage3 <= 4'h4;
                    {4'd0, 4'b1011}: key_value_stage3 <= 4'h7;
                    {4'd0, 4'b0111}: key_value_stage3 <= 4'hE;
                    {4'd1, 4'b1110}: key_value_stage3 <= 4'h2;
                    {4'd1, 4'b1101}: key_value_stage3 <= 4'h5;
                    {4'd1, 4'b1011}: key_value_stage3 <= 4'h8;
                    {4'd1, 4'b0111}: key_value_stage3 <= 4'h0;
                    {4'd2, 4'b1110}: key_value_stage3 <= 4'h3;
                    {4'd2, 4'b1101}: key_value_stage3 <= 4'h6;
                    {4'd2, 4'b1011}: key_value_stage3 <= 4'h9;
                    {4'd2, 4'b0111}: key_value_stage3 <= 4'hF;
                    {4'd3, 4'b1110}: key_value_stage3 <= 4'hA;
                    {4'd3, 4'b1101}: key_value_stage3 <= 4'hB;
                    {4'd3, 4'b1011}: key_value_stage3 <= 4'hC;
                    {4'd3, 4'b0111}: key_value_stage3 <= 4'hD;
                    default: key_value_stage3 <= 4'h0;
                endcase
            end else begin
                key_valid_stage3 <= 1'b0;
            end
        end
    end
    
    // Next state logic
    always @(*) begin
        case (state_stage1)
            IDLE: next_stage1 = SCAN;
            SCAN: next_stage1 = (row_reg_stage1 != 4'b1111) ? DEBOUNCE : 
                              (col_cnt_stage1 == 4'd3) ? IDLE : SCAN;
            DEBOUNCE: next_stage1 = (debounce_cnt_stage2 == 8'd255 && key_pressed_stage2) ? 
                                   OUTPUT : DEBOUNCE;
            OUTPUT: next_stage1 = IDLE;
            default: next_stage1 = IDLE;
        endcase
    end
    
    // Output assignments
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cols <= 4'b0000;
            key_value <= 4'd0;
            key_valid <= 1'b0;
        end else begin
            cols <= cols_stage1;
            key_value <= key_value_stage3;
            key_valid <= key_valid_stage3;
        end
    end
    
endmodule