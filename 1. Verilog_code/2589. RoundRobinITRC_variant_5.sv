//SystemVerilog
module RoundRobinITRC #(parameter WIDTH=8) (
    input wire clock, reset,
    input wire [WIDTH-1:0] interrupts,
    output reg service_req,
    output reg [2:0] service_id
);
    reg [2:0] current_position;
    reg [2:0] next_position;
    reg [2:0] next_service_id;
    
    // Reset and service request generation
    always @(posedge clock) begin
        if (reset) begin
            current_position <= 0;
            service_req <= 0;
            service_id <= 0;
        end else begin
            current_position <= next_position;
            service_req <= |interrupts;
            service_id <= next_service_id;
        end
    end
    
    // Next position and service ID calculation
    always @(*) begin
        next_position = current_position;
        next_service_id = service_id;
        
        if (|interrupts) begin
            case (current_position)
                0: begin
                    if (interrupts[0]) begin
                        next_service_id = 0;
                        next_position = 1;
                    end
                    else if (interrupts[1]) begin
                        next_service_id = 1;
                        next_position = 2;
                    end
                    else if (interrupts[2]) begin
                        next_service_id = 2;
                        next_position = 3;
                    end
                    else if (interrupts[3]) begin
                        next_service_id = 3;
                        next_position = 4;
                    end
                    else if (interrupts[4]) begin
                        next_service_id = 4;
                        next_position = 5;
                    end
                    else if (interrupts[5]) begin
                        next_service_id = 5;
                        next_position = 6;
                    end
                    else if (interrupts[6]) begin
                        next_service_id = 6;
                        next_position = 7;
                    end
                    else if (interrupts[7]) begin
                        next_service_id = 7;
                        next_position = 0;
                    end
                end
                1: begin
                    if (interrupts[1]) begin
                        next_service_id = 1;
                        next_position = 2;
                    end
                    else if (interrupts[2]) begin
                        next_service_id = 2;
                        next_position = 3;
                    end
                    else if (interrupts[3]) begin
                        next_service_id = 3;
                        next_position = 4;
                    end
                    else if (interrupts[4]) begin
                        next_service_id = 4;
                        next_position = 5;
                    end
                    else if (interrupts[5]) begin
                        next_service_id = 5;
                        next_position = 6;
                    end
                    else if (interrupts[6]) begin
                        next_service_id = 6;
                        next_position = 7;
                    end
                    else if (interrupts[7]) begin
                        next_service_id = 7;
                        next_position = 0;
                    end
                    else if (interrupts[0]) begin
                        next_service_id = 0;
                        next_position = 1;
                    end
                end
                default: next_position = 0;
            endcase
        end
    end
endmodule