//SystemVerilog
module Wallace_Multiplier_5bit_Pipelined (
    input clk,
    input rst_n,
    input [4:0] a,
    input [4:0] b,
    input valid_in,
    output reg valid_out,
    output reg [9:0] product
);

    // Stage 1: Partial products generation
    reg [4:0] pp0_s1, pp1_s1, pp2_s1, pp3_s1, pp4_s1;
    reg [4:0] a_s1, b_s1;
    reg valid_s1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pp0_s1 <= 5'b0;
            pp1_s1 <= 5'b0;
            pp2_s1 <= 5'b0;
            pp3_s1 <= 5'b0;
            pp4_s1 <= 5'b0;
            a_s1 <= 5'b0;
            b_s1 <= 5'b0;
            valid_s1 <= 1'b0;
        end else begin
            pp0_s1 <= a & {5{b[0]}};
            pp1_s1 <= a & {5{b[1]}};
            pp2_s1 <= a & {5{b[2]}};
            pp3_s1 <= a & {5{b[3]}};
            pp4_s1 <= a & {5{b[4]}};
            a_s1 <= a;
            b_s1 <= b;
            valid_s1 <= valid_in;
        end
    end

    // Stage 2: First level of compression
    reg [5:0] sum1_s2, carry1_s2;
    reg [4:0] pp0_s2, pp1_s2, pp2_s2, pp3_s2, pp4_s2;
    reg valid_s2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum1_s2 <= 6'b0;
            carry1_s2 <= 6'b0;
            pp0_s2 <= 5'b0;
            pp1_s2 <= 5'b0;
            pp2_s2 <= 5'b0;
            pp3_s2 <= 5'b0;
            pp4_s2 <= 5'b0;
            valid_s2 <= 1'b0;
        end else begin
            {carry1_s2[0], sum1_s2[0]} <= pp0_s1[0];
            {carry1_s2[1], sum1_s2[1]} <= pp0_s1[1] + pp1_s1[0];
            {carry1_s2[2], sum1_s2[2]} <= pp0_s1[2] + pp1_s1[1] + pp2_s1[0];
            {carry1_s2[3], sum1_s2[3]} <= pp0_s1[3] + pp1_s1[2] + pp2_s1[1] + pp3_s1[0];
            {carry1_s2[4], sum1_s2[4]} <= pp0_s1[4] + pp1_s1[3] + pp2_s1[2] + pp3_s1[1] + pp4_s1[0];
            {carry1_s2[5], sum1_s2[5]} <= pp1_s1[4] + pp2_s1[3] + pp3_s1[2] + pp4_s1[1];
            pp0_s2 <= pp0_s1;
            pp1_s2 <= pp1_s1;
            pp2_s2 <= pp2_s1;
            pp3_s2 <= pp3_s1;
            pp4_s2 <= pp4_s1;
            valid_s2 <= valid_s1;
        end
    end

    // Stage 3: Second level of compression
    reg [5:0] sum2_s3, carry2_s3;
    reg [5:0] sum1_s3, carry1_s3;
    reg [4:0] pp2_s3, pp3_s3, pp4_s3;
    reg valid_s3;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum2_s3 <= 6'b0;
            carry2_s3 <= 6'b0;
            sum1_s3 <= 6'b0;
            carry1_s3 <= 6'b0;
            pp2_s3 <= 5'b0;
            pp3_s3 <= 5'b0;
            pp4_s3 <= 5'b0;
            valid_s3 <= 1'b0;
        end else begin
            {carry2_s3[0], sum2_s3[0]} <= sum1_s2[0];
            {carry2_s3[1], sum2_s3[1]} <= sum1_s2[1] + carry1_s2[0];
            {carry2_s3[2], sum2_s3[2]} <= sum1_s2[2] + carry1_s2[1];
            {carry2_s3[3], sum2_s3[3]} <= sum1_s2[3] + carry1_s2[2];
            {carry2_s3[4], sum2_s3[4]} <= sum1_s2[4] + carry1_s2[3];
            {carry2_s3[5], sum2_s3[5]} <= sum1_s2[5] + carry1_s2[4];
            sum1_s3 <= sum1_s2;
            carry1_s3 <= carry1_s2;
            pp2_s3 <= pp2_s2;
            pp3_s3 <= pp3_s2;
            pp4_s3 <= pp4_s2;
            valid_s3 <= valid_s2;
        end
    end

    // Stage 4: Third level of compression
    reg [5:0] sum3_s4, carry3_s4;
    reg [4:0] pp2_s4, pp3_s4, pp4_s4;
    reg valid_s4;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum3_s4 <= 6'b0;
            carry3_s4 <= 6'b0;
            pp2_s4 <= 5'b0;
            pp3_s4 <= 5'b0;
            pp4_s4 <= 5'b0;
            valid_s4 <= 1'b0;
        end else begin
            {carry3_s4[0], sum3_s4[0]} <= sum2_s3[0];
            {carry3_s4[1], sum3_s4[1]} <= sum2_s3[1] + carry2_s3[0];
            {carry3_s4[2], sum3_s4[2]} <= sum2_s3[2] + carry2_s3[1];
            {carry3_s4[3], sum3_s4[3]} <= sum2_s3[3] + carry2_s3[2];
            {carry3_s4[4], sum3_s4[4]} <= sum2_s3[4] + carry2_s3[3];
            {carry3_s4[5], sum3_s4[5]} <= sum2_s3[5] + carry2_s3[4];
            pp2_s4 <= pp2_s3;
            pp3_s4 <= pp3_s3;
            pp4_s4 <= pp4_s3;
            valid_s4 <= valid_s3;
        end
    end

    // Stage 5: Final addition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product <= 10'b0;
            valid_out <= 1'b0;
        end else begin
            product[0] <= sum3_s4[0];
            product[1] <= sum3_s4[1] + carry3_s4[0];
            product[2] <= sum3_s4[2] + carry3_s4[1];
            product[3] <= sum3_s4[3] + carry3_s4[2];
            product[4] <= sum3_s4[4] + carry3_s4[3];
            product[5] <= sum3_s4[5] + carry3_s4[4];
            product[6] <= pp2_s4[4] + pp3_s4[3] + pp4_s4[2] + carry3_s4[5];
            product[7] <= pp3_s4[4] + pp4_s4[3];
            product[8] <= pp4_s4[4];
            product[9] <= 1'b0;
            valid_out <= valid_s4;
        end
    end
endmodule

module SPI_Master_Pipelined #(
    parameter DATA_WIDTH = 8,
    parameter CPOL = 0,
    parameter CPHA = 0
)(
    input clk, rst_n,
    input start,
    input [DATA_WIDTH-1:0] tx_data,
    output reg [DATA_WIDTH-1:0] rx_data,
    output reg busy,
    output sclk,
    output reg cs,
    output mosi,
    input miso
);

    localparam IDLE = 1'b0, ACTIVE = 1'b1;
    reg current_state, next_state;
    
    reg [DATA_WIDTH-1:0] shift_reg;
    reg [4:0] bit_counter;
    reg sclk_int;
    reg mosi_reg;
    wire [4:0] max_bits = DATA_WIDTH * 2;
    wire sclk_edge = (CPHA == 0) ? ~sclk_int : sclk_int;
    wire sample_edge = (CPHA == 0) ? ~sclk_int : sclk_int;
    wire shift_edge = (CPHA == 0) ? sclk_int : ~sclk_int;

    // Pipeline control signals
    reg mult_valid_in;
    wire mult_valid_out;
    reg [4:0] mult_a;
    
    // Instantiate pipelined Wallace multiplier
    wire [9:0] mult_result;
    Wallace_Multiplier_5bit_Pipelined multiplier (
        .clk(clk),
        .rst_n(rst_n),
        .a(mult_a),
        .b(5'b00010),
        .valid_in(mult_valid_in),
        .valid_out(mult_valid_out),
        .product(mult_result)
    );

    // Pipeline Stage 1: Calculate multiplier input
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mult_a <= 5'b0;
            mult_valid_in <= 1'b0;
        end else begin
            mult_a <= bit_counter;
            mult_valid_in <= (current_state == ACTIVE && bit_counter < max_bits);
        end
    end

    // FSM and main control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            sclk_int <= CPOL;
            bit_counter <= 0;
            shift_reg <= 0;
            rx_data <= 0;
            cs <= 1'b1;
            mosi_reg <= 1'b0;
            busy <= 0;
        end else begin
            current_state <= next_state;
            busy <= (current_state != IDLE);
            
            case(current_state)
                IDLE: begin
                    sclk_int <= CPOL;
                    bit_counter <= 0;
                    if (start) begin
                        shift_reg <= tx_data;
                        cs <= 1'b0;
                    end
                end
                ACTIVE: begin
                    if (bit_counter < max_bits) begin
                        sclk_int <= ~sclk_int;
                        
                        if (sample_edge) begin
                            shift_reg <= {shift_reg[DATA_WIDTH-2:0], miso};
                            // Use multiplier result only when valid
                            if (mult_valid_out) begin
                                bit_counter <= mult_result[4:0];
                            end
                        end 
                        else if (shift_edge) begin
                            mosi_reg <= shift_reg[DATA_WIDTH-1];
                            // Use multiplier result only when valid
                            if (mult_valid_out) begin
                                bit_counter <= mult_result[4:0];
                            end
                        end
                    end else begin
                        rx_data <= shift_reg;
                        cs <= 1'b1;
                    end
                end
            endcase
        end
    end

    always @(*) begin
        next_state = current_state;
        case(current_state)
            IDLE: next_state = start ? ACTIVE : IDLE;
            ACTIVE: next_state = (bit_counter >= max_bits) ? IDLE : ACTIVE;
        endcase
    end

    assign sclk = (current_state == ACTIVE) ? sclk_int : CPOL;
    assign mosi = mosi_reg;
endmodule