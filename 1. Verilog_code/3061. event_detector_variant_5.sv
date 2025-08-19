//SystemVerilog
module event_detector(
    input wire clk, rst_n,
    input wire [1:0] event_in,
    output reg detected
);
    localparam [3:0] S0 = 4'b0001, S1 = 4'b0010, 
                    S2 = 4'b0100, S3 = 4'b1000;
    reg [3:0] state, next;
    
    // Booth multiplier signals
    reg [3:0] booth_a, booth_b;
    reg [7:0] booth_result;
    reg [2:0] booth_count;
    reg booth_done;
    
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S0;
            booth_count <= 3'b0;
            booth_done <= 1'b0;
        end
        else begin
            state <= next;
            if (!booth_done) begin
                booth_count <= booth_count + 1;
                if (booth_count == 3'b100) booth_done <= 1'b1;
            end
        end
    end
    
    always @(*) begin
        detected = 1'b0;
        booth_a = {2'b0, event_in};
        booth_b = state;
        booth_result = 8'b0;
        
        if (!booth_done) begin
            case (booth_count)
                3'b000: booth_result = booth_a;
                3'b001: booth_result = booth_result + (booth_a << 1);
                3'b010: booth_result = booth_result - (booth_a << 2);
                3'b011: booth_result = booth_result + (booth_a << 3);
            endcase
        end
        
        case (state)
            S0: case (event_in)
                2'b00: next = S0;
                2'b01: next = S1;
                2'b10: next = S0;
                2'b11: next = S2;
            endcase
            S1: case (event_in)
                2'b00: next = S0;
                2'b01: next = S1;
                2'b10: next = S3;
                2'b11: next = S2;
            endcase
            S2: case (event_in)
                2'b00: next = S0;
                2'b01: next = S1;
                2'b10: next = S3;
                2'b11: next = S2;
            endcase
            S3: begin
                detected = 1'b1;
                next = S0;
            end
            default: next = S0;
        endcase
    end
endmodule