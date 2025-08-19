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
    
    // Manchester carry chain adder for debounce counter
    wire [7:0] debounce_sum;
    wire [7:0] carry_chain;
    
    // Generate propagate and generate signals
    wire [7:0] p = debounce_cnt;
    wire [7:0] g = 8'b00000001;
    
    // Manchester carry chain
    assign carry_chain[0] = g[0];
    assign carry_chain[1] = g[1] | (p[1] & carry_chain[0]);
    assign carry_chain[2] = g[2] | (p[2] & carry_chain[1]);
    assign carry_chain[3] = g[3] | (p[3] & carry_chain[2]);
    assign carry_chain[4] = g[4] | (p[4] & carry_chain[3]);
    assign carry_chain[5] = g[5] | (p[5] & carry_chain[4]);
    assign carry_chain[6] = g[6] | (p[6] & carry_chain[5]);
    assign carry_chain[7] = g[7] | (p[7] & carry_chain[6]);
    
    // Sum generation
    assign debounce_sum = p ^ {carry_chain[6:0], 1'b0};

    // State register update
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next;
        end

    // Row input sampling
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            row_reg <= 4'b1111;
        end else begin
            row_reg <= rows;
        end

    // Column control
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            cols <= 4'b0000;
            col_cnt <= 4'd0;
        end else if (state == IDLE) begin
            cols <= 4'b1110;
            col_cnt <= 4'd0;
        end else if (state == SCAN && row_reg == 4'b1111) begin
            cols <= {cols[0], cols[3:1]};
            col_cnt <= col_cnt + 4'd1;
        end

    // Debounce counter with Manchester carry chain
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            debounce_cnt <= 8'd0;
        end else if (state == SCAN && row_reg != 4'b1111) begin
            debounce_cnt <= 8'd0;
        end else if (state == DEBOUNCE) begin
            debounce_cnt <= debounce_sum;
        end

    // Key value generation
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            key_value <= 4'd0;
        end else if (state == DEBOUNCE && debounce_cnt == 8'd255 && row_reg != 4'b1111) begin
            case ({col_cnt, row_reg})
                {4'd0, 4'b1110}: key_value <= 4'h1;
                {4'd0, 4'b1101}: key_value <= 4'h4;
                {4'd0, 4'b1011}: key_value <= 4'h7;
                {4'd0, 4'b0111}: key_value <= 4'hE;
                {4'd1, 4'b1110}: key_value <= 4'h2;
                {4'd1, 4'b1101}: key_value <= 4'h5;
                {4'd1, 4'b1011}: key_value <= 4'h8;
                {4'd1, 4'b0111}: key_value <= 4'h0;
                {4'd2, 4'b1110}: key_value <= 4'h3;
                {4'd2, 4'b1101}: key_value <= 4'h6;
                {4'd2, 4'b1011}: key_value <= 4'h9;
                {4'd2, 4'b0111}: key_value <= 4'hF;
                {4'd3, 4'b1110}: key_value <= 4'hA;
                {4'd3, 4'b1101}: key_value <= 4'hB;
                {4'd3, 4'b1011}: key_value <= 4'hC;
                {4'd3, 4'b0111}: key_value <= 4'hD;
                default: key_value <= 4'h0;
            endcase
        end

    // Key valid signal
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            key_valid <= 1'b0;
        end else if (state == IDLE) begin
            key_valid <= 1'b0;
        end else if (state == OUTPUT) begin
            key_valid <= 1'b1;
        end

    // Next state logic
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