//SystemVerilog
module seq_detector_0110(
    input wire clk, rst_n, x,
    output reg z
);
    parameter S0=2'b00, S1=2'b01, S2=2'b10, S3=2'b11;
    reg [1:0] state, next_state;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S0;
        end else begin
            state <= next_state;
        end
    end
    
    always @(*) begin
        if (state == S0) begin
            if (x) begin
                next_state = S1;
            end else begin
                next_state = S0;
            end
        end else if (state == S1) begin
            if (x) begin
                next_state = S1;
            end else begin
                next_state = S2;
            end
        end else if (state == S2) begin
            if (x) begin
                next_state = S3;
            end else begin
                next_state = S0;
            end
        end else if (state == S3) begin
            if (x) begin
                next_state = S1;
            end else begin
                next_state = S2;
            end
        end else begin
            next_state = S0;
        end
        
        if ((state == S3) && (x == 0)) begin
            z = 1'b1;
        end else begin
            z = 1'b0;
        end
    end
endmodule