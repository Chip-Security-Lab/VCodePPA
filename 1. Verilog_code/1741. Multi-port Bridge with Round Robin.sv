module rr_bridge #(parameter DWIDTH=32, PORTS=3) (
    input clk, rst_n,
    input [PORTS-1:0] req,
    input [DWIDTH*PORTS-1:0] data_in_flat, // Changed to flat array
    output reg [PORTS-1:0] grant,
    output reg [DWIDTH-1:0] data_out,
    output reg valid,
    input ready
);
    // Convert flat array to individual ports
    wire [DWIDTH-1:0] data_in[0:PORTS-1];
    genvar g;
    generate
        for(g=0; g<PORTS; g=g+1) begin : gen_data
            assign data_in[g] = data_in_flat[(g+1)*DWIDTH-1:g*DWIDTH];
        end
    endgenerate
    
    reg [1:0] current, next;
    
    // Round-robin next port selection
    always @(*) begin
        next = current;
        casez ({req[0], req[1], req[2]})
            3'b??1: next = 2'd0;
            3'b?10: next = 2'd1;
            3'b100: next = 2'd2;
            default: next = current;
        endcase
        
        // Now adjust based on current position
        case (current)
            2'd0: begin
                casez ({req[1], req[2], req[0]})
                    3'b??1: next = 2'd0;
                    3'b?10: next = 2'd2;
                    3'b100: next = 2'd1;
                    default: next = current;
                endcase
            end
            2'd1: begin
                casez ({req[2], req[0], req[1]})
                    3'b??1: next = 2'd1;
                    3'b?10: next = 2'd0;
                    3'b100: next = 2'd2;
                    default: next = current;
                endcase
            end
            2'd2: begin
                casez ({req[0], req[1], req[2]})
                    3'b??1: next = 2'd2;
                    3'b?10: next = 2'd1;
                    3'b100: next = 2'd0;
                    default: next = current;
                endcase
            end
        endcase
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current <= 0; 
            valid <= 0;
            data_out <= 0;
            grant <= 0;
        end else if (!valid || ready) begin
            if (req[next]) begin
                grant <= (1 << next);
                data_out <= data_in[next];
                valid <= 1;
                current <= next;
            end else begin
                valid <= 0;
                grant <= 0;
            end
        end else if (valid && ready) begin
            valid <= 0;
            grant <= 0;
        end
    end
endmodule