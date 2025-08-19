//SystemVerilog
module rr_bridge #(parameter DWIDTH=32, PORTS=3) (
    input clk, rst_n,
    input [PORTS-1:0] req,
    input [DWIDTH*PORTS-1:0] data_in_flat,
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
    
    // State registers
    reg [1:0] current, next;
    
    // Intermediate control signals
    reg update_outputs;
    reg clear_outputs;
    
    // Round-robin priority encoder based on current position
    always @(*) begin
        next = current;
        
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
            
            default: next = current;
        endcase
    end
    
    // Control signals logic
    always @(*) begin
        update_outputs = 0;
        clear_outputs = 0;
        
        if (!valid || ready) begin
            if (req[next]) begin
                update_outputs = 1;
            end else begin
                clear_outputs = 1;
            end
        end else if (valid && ready) begin
            clear_outputs = 1;
        end
    end
    
    // Update current state register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current <= 2'd0;
        end else if (update_outputs) begin
            current <= next;
        end
    end
    
    // Update output signals - grant and data_out
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant <= 0;
            data_out <= 0;
        end else if (update_outputs) begin
            grant <= (1'b1 << next);
            data_out <= data_in[next];
        end else if (clear_outputs) begin
            grant <= 0;
            // data_out is maintained for potential downstream logic
        end
    end
    
    // Update valid signal with separate logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid <= 1'b0;
        end else if (update_outputs) begin
            valid <= 1'b1;
        end else if (clear_outputs) begin
            valid <= 1'b0;
        end
    end
    
endmodule