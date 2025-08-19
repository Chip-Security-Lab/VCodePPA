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

    reg [1:0] current;
    wire [PORTS-1:0] shifted_req;
    wire [PORTS-1:0] barrel_req;
    
    // Barrel shifter for request vector
    assign shifted_req = {req[PORTS-2:0], req[PORTS-1]};
    assign barrel_req = (current == 2'd0) ? req :
                       (current == 2'd1) ? shifted_req :
                       {shifted_req[PORTS-2:0], shifted_req[PORTS-1]};

    // Priority encoder for next port selection
    reg [1:0] next;
    always @(*) begin
        next = current;
        casez (barrel_req)
            3'b??1: next = 2'd0;
            3'b?10: next = 2'd1;
            3'b100: next = 2'd2;
            default: next = current;
        endcase
    end

    // Register to capture next values for retiming
    reg [1:0] next_r;
    reg req_next_valid;
    
    // Pre-compute barrel shifted data to reduce critical path
    reg [DWIDTH-1:0] barrel_data_r [0:PORTS-1];
    reg [PORTS-1:0] grant_pre;
    
    // Retimed registers for data path
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_r <= 0;
            req_next_valid <= 0;
            barrel_data_r[0] <= 0;
            barrel_data_r[1] <= 0;
            barrel_data_r[2] <= 0;
            grant_pre <= 0;
        end else begin
            next_r <= next;
            req_next_valid <= req[next];
            barrel_data_r[0] <= data_in[0];
            barrel_data_r[1] <= data_in[1];
            barrel_data_r[2] <= data_in[2];
            grant_pre <= (1 << next);
        end
    end

    // Output stage with reduced logic in critical path
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current <= 0;
            valid <= 0;
            data_out <= 0;
            grant <= 0;
        end else if (!valid || ready) begin
            if (req_next_valid) begin
                grant <= grant_pre;
                data_out <= (next_r == 2'd0) ? barrel_data_r[0] :
                           (next_r == 2'd1) ? barrel_data_r[1] :
                           barrel_data_r[2];
                valid <= 1;
                current <= next_r;
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