//SystemVerilog
module event_detector(
    input wire clk, rst_n,
    input wire [1:0] event_in,
    output reg detected
);
    localparam [3:0] S0 = 4'b0001, S1 = 4'b0010, 
                    S2 = 4'b0100, S3 = 4'b1000;
    reg [3:0] state, next;
    reg [3:0] state_d1;
    reg [1:0] event_in_d1;
    reg detected_next;
    
    // Wallace tree multiplier signals
    wire [3:0] partial_products [3:0];
    wire [3:0] sum_stage1 [1:0];
    wire [3:0] sum_stage2;
    wire [3:0] final_product;
    
    // Generate partial products
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : pp_gen
            assign partial_products[i] = {4{event_in[0]}} & {4{state[i]}};
        end
    endgenerate
    
    // First stage of Wallace tree
    assign sum_stage1[0] = partial_products[0] + partial_products[1];
    assign sum_stage1[1] = partial_products[2] + partial_products[3];
    
    // Second stage of Wallace tree
    assign sum_stage2 = sum_stage1[0] + sum_stage1[1];
    
    // Final product
    assign final_product = sum_stage2;
    
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S0;
            state_d1 <= S0;
            event_in_d1 <= 2'b0;
            detected <= 1'b0;
        end else begin
            state <= next;
            state_d1 <= state;
            event_in_d1 <= event_in;
            detected <= detected_next;
        end
    end
    
    always @(*) begin
        detected_next = 1'b0;
        if (state == S0) begin
            if (event_in == 2'b00) next = S0;
            else if (event_in == 2'b01) next = S1;
            else if (event_in == 2'b10) next = S0;
            else if (event_in == 2'b11) next = S2;
            else next = S0;
        end
        else if (state == S1) begin
            if (event_in == 2'b00) next = S0;
            else if (event_in == 2'b01) next = S1;
            else if (event_in == 2'b10) next = S3;
            else if (event_in == 2'b11) next = S2;
            else next = S0;
        end
        else if (state == S2) begin
            if (event_in == 2'b00) next = S0;
            else if (event_in == 2'b01) next = S1;
            else if (event_in == 2'b10) next = S3;
            else if (event_in == 2'b11) next = S2;
            else next = S0;
        end
        else if (state == S3) begin
            detected_next = 1'b1;
            next = S0;
        end
        else begin
            next = S0;
        end
    end
endmodule