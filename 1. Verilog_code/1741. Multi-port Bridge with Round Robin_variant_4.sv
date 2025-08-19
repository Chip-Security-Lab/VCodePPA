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
    
    // 2-bit LUT-based subtractor
    reg [1:0] sub_lut [0:15];
    initial begin
        // a[1:0] - b[1:0] = sub_lut[{a,b}]
        sub_lut[0] = 2'b00;  // 0-0=0
        sub_lut[1] = 2'b11;  // 0-1=3
        sub_lut[2] = 2'b10;  // 0-2=2
        sub_lut[3] = 2'b01;  // 0-3=1
        sub_lut[4] = 2'b01;  // 1-0=1
        sub_lut[5] = 2'b00;  // 1-1=0
        sub_lut[6] = 2'b11;  // 1-2=3
        sub_lut[7] = 2'b10;  // 1-3=2
        sub_lut[8] = 2'b10;  // 2-0=2
        sub_lut[9] = 2'b01;  // 2-1=1
        sub_lut[10] = 2'b00; // 2-2=0
        sub_lut[11] = 2'b11; // 2-3=3
        sub_lut[12] = 2'b11; // 3-0=3
        sub_lut[13] = 2'b10; // 3-1=2
        sub_lut[14] = 2'b01; // 3-2=1
        sub_lut[15] = 2'b00; // 3-3=0
    end
    
    wire [3:0] sub_addr = {next, 2'b00};
    wire [1:0] sub_result = sub_lut[sub_addr];
    
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
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current <= 0;
            valid <= 0;
            data_out <= 0;
            grant <= 0;
        end else if (!valid || ready) begin
            if (req[next]) begin
                grant <= (1 << next);
                data_out <= {30'b0, sub_result};
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