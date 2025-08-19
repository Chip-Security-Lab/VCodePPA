module RoundRobinITRC #(parameter WIDTH=8) (
    input wire clock, reset,
    input wire [WIDTH-1:0] interrupts,
    output reg service_req,
    output reg [2:0] service_id
);
    reg [2:0] current_position;
    
    always @(posedge clock) begin
        if (reset) begin
            current_position <= 0;
            service_req <= 0;
            service_id <= 0;
        end else begin
            service_req <= |interrupts;
            
            if (|interrupts) begin
                // Implementation of round-robin without variable slicing
                case (current_position)
                    0: begin
                        if (interrupts[0]) begin
                            service_id <= 0;
                            current_position <= 1;
                        end
                        else if (interrupts[1]) begin
                            service_id <= 1;
                            current_position <= 2;
                        end
                        else if (interrupts[2]) begin
                            service_id <= 2;
                            current_position <= 3;
                        end
                        else if (interrupts[3]) begin
                            service_id <= 3;
                            current_position <= 4;
                        end
                        else if (interrupts[4]) begin
                            service_id <= 4;
                            current_position <= 5;
                        end
                        else if (interrupts[5]) begin
                            service_id <= 5;
                            current_position <= 6;
                        end
                        else if (interrupts[6]) begin
                            service_id <= 6;
                            current_position <= 7;
                        end
                        else if (interrupts[7]) begin
                            service_id <= 7;
                            current_position <= 0;
                        end
                    end
                    1: begin
                        if (interrupts[1]) begin
                            service_id <= 1;
                            current_position <= 2;
                        end
                        else if (interrupts[2]) begin
                            service_id <= 2;
                            current_position <= 3;
                        end
                        else if (interrupts[3]) begin
                            service_id <= 3;
                            current_position <= 4;
                        end
                        else if (interrupts[4]) begin
                            service_id <= 4;
                            current_position <= 5;
                        end
                        else if (interrupts[5]) begin
                            service_id <= 5;
                            current_position <= 6;
                        end
                        else if (interrupts[6]) begin
                            service_id <= 6;
                            current_position <= 7;
                        end
                        else if (interrupts[7]) begin
                            service_id <= 7;
                            current_position <= 0;
                        end
                        else if (interrupts[0]) begin
                            service_id <= 0;
                            current_position <= 1;
                        end
                    end
                    default: current_position <= 0;
                endcase
            end
        end
    end
endmodule