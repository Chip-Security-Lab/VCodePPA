//SystemVerilog
module event_detector(
    input wire clk, rst_n,
    input wire [1:0] event_in,
    input wire req,
    output reg ack,
    output reg detected
);
    localparam [3:0] S0 = 4'b0001, S1 = 4'b0010, 
                    S2 = 4'b0100, S3 = 4'b1000;
    reg [3:0] state, next;
    reg req_reg;
    
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            state <= S0;
            req_reg <= 1'b0;
            ack <= 1'b0;
        end else begin
            state <= next;
            req_reg <= req;
            ack <= req_reg;
        end
    
    always @(*) begin
        detected = 1'b0;
        next = S0; // 默认值
        
        if (state == S0) begin
            if (event_in == 2'b00)
                next = S0;
            else if (event_in == 2'b01)
                next = S1;
            else if (event_in == 2'b10)
                next = S0;
            else if (event_in == 2'b11)
                next = S2;
        end else if (state == S1) begin
            if (event_in == 2'b00)
                next = S0;
            else if (event_in == 2'b01)
                next = S1;
            else if (event_in == 2'b10)
                next = S3;
            else if (event_in == 2'b11)
                next = S2;
        end else if (state == S2) begin
            if (event_in == 2'b00)
                next = S0;
            else if (event_in == 2'b01)
                next = S1;
            else if (event_in == 2'b10)
                next = S3;
            else if (event_in == 2'b11)
                next = S2;
        end else if (state == S3) begin
            detected = 1'b1;
            next = S0;
        end
    end
endmodule