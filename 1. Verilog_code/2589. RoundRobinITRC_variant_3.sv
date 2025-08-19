//SystemVerilog
module RoundRobinITRC #(parameter WIDTH=8) (
    input wire clock, reset,
    input wire [WIDTH-1:0] interrupts,
    output reg service_req,
    output reg [2:0] service_id
);
    reg [2:0] current_position;
    wire [WIDTH-1:0] masked_interrupts;
    wire [2:0] next_position;
    
    // Generate masked interrupts based on current position
    assign masked_interrupts = interrupts & ((1 << (current_position + 1)) - 1);
    
    // Priority encoder for next service ID
    always @(*) begin
        casez (masked_interrupts)
            8'b???????1: service_id = 3'd0;
            8'b??????10: service_id = 3'd1;
            8'b?????100: service_id = 3'd2;
            8'b????1000: service_id = 3'd3;
            8'b???10000: service_id = 3'd4;
            8'b??100000: service_id = 3'd5;
            8'b?1000000: service_id = 3'd6;
            8'b10000000: service_id = 3'd7;
            default: service_id = 3'd0;
        endcase
    end
    
    // Calculate next position
    assign next_position = (service_id + 1) % WIDTH;
    
    always @(posedge clock) begin
        if (reset) begin
            current_position <= 0;
            service_req <= 0;
        end else begin
            service_req <= |interrupts;
            if (|masked_interrupts) begin
                current_position <= next_position;
            end
        end
    end
endmodule