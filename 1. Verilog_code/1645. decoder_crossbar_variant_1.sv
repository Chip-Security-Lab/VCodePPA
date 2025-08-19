//SystemVerilog
module decoder_crossbar #(
    parameter MASTERS = 2,
    parameter SLAVES = 4
) (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire [MASTERS-1:0]       master_req,
    input  wire [MASTERS-1:0][7:0]  addr,
    output reg  [MASTERS-1:0][SLAVES-1:0] slave_sel
);

    reg [MASTERS-1:0]       master_req_reg;
    reg [MASTERS-1:0][7:0]  addr_reg;
    reg [MASTERS-1:0][SLAVES-1:0] slave_sel_next;
    
    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            master_req_reg <= {MASTERS{1'b0}};
            addr_reg <= {MASTERS{8'b0}};
        end else begin
            master_req_reg <= master_req;
            addr_reg <= addr;
        end
    end
    
    // Stage 2: Decode logic with conditional inversion
    genvar i;
    generate
        for (i = 0; i < MASTERS; i = i + 1) begin : master_decode
            wire [7:0] addr_mod;
            wire [SLAVES-1:0] decoded_slave;
            
            // Conditional inversion based on MSB
            wire [7:0] addr_inv = ~addr_reg[i];
            wire [7:0] addr_sel = addr_reg[i][7] ? addr_inv : addr_reg[i];
            
            // Modulo operation using conditional inversion
            assign addr_mod = addr_sel % SLAVES;
            
            // Decode with conditional inversion
            assign decoded_slave = master_req_reg[i] ? (1 << addr_mod) : {SLAVES{1'b0}};
            
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    slave_sel_next[i] <= {SLAVES{1'b0}};
                end else begin
                    slave_sel_next[i] <= decoded_slave;
                end
            end
        end
    endgenerate
    
    // Stage 3: Output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            slave_sel <= {MASTERS{1'b0}};
        end else begin
            slave_sel <= slave_sel_next;
        end
    end

endmodule