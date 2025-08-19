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

    wire [DWIDTH-1:0] data_in[0:PORTS-1];
    genvar g;
    generate
        for(g=0; g<PORTS; g=g+1) begin : gen_data
            assign data_in[g] = data_in_flat[(g+1)*DWIDTH-1:g*DWIDTH];
        end
    endgenerate
    
    reg [1:0] current, next;
    reg [1:0] next_stage1, next_stage2;
    reg valid_stage1, valid_stage2;
    reg [DWIDTH-1:0] data_out_stage1, data_out_stage2;
    reg [PORTS-1:0] grant_stage1, grant_stage2;
    reg req_valid_stage1, req_valid_stage2;

    // Stage 1: Next port selection logic
    always @(*) begin
        next = current;
        casez ({req[0], req[1], req[2]})
            3'b??1: next = 2'd0;
            3'b?10: next = 2'd1;
            3'b100: next = 2'd2;
            default: next = current;
        endcase
        
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

    // Pipeline stages
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current <= 0;
            next_stage1 <= 0;
            next_stage2 <= 0;
            valid <= 0;
            valid_stage1 <= 0;
            valid_stage2 <= 0;
            data_out <= 0;
            data_out_stage1 <= 0;
            data_out_stage2 <= 0;
            grant <= 0;
            grant_stage1 <= 0;
            grant_stage2 <= 0;
            req_valid_stage1 <= 0;
            req_valid_stage2 <= 0;
        end else begin
            // Stage 1: Register next selection and request status
            next_stage1 <= next;
            req_valid_stage1 <= req[next];
            
            // Stage 2: Prepare grant and data
            next_stage2 <= next_stage1;
            req_valid_stage2 <= req_valid_stage1;
            if (req_valid_stage1) begin
                grant_stage1 <= (1 << next_stage1);
                data_out_stage1 <= data_in[next_stage1];
                valid_stage1 <= 1;
            end else begin
                grant_stage1 <= 0;
                valid_stage1 <= 0;
            end
            
            // Stage 3: Output stage with ready handshake
            if (!valid_stage2 || ready) begin
                if (req_valid_stage2) begin
                    grant <= grant_stage1;
                    data_out <= data_out_stage1;
                    valid <= valid_stage1;
                    current <= next_stage2;
                end else begin
                    valid <= 0;
                    grant <= 0;
                end
            end else if (valid_stage2 && ready) begin
                valid <= 0;
                grant <= 0;
            end
        end
    end
endmodule