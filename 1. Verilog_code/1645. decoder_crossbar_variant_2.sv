//SystemVerilog
// Top level crossbar module
module decoder_crossbar #(
    parameter MASTERS = 2,
    parameter SLAVES = 4
)(
    input [MASTERS-1:0] master_req,
    input [MASTERS-1:0][7:0] addr,
    output [MASTERS-1:0][SLAVES-1:0] slave_sel
);

    crossbar_controller #(
        .MASTERS(MASTERS),
        .SLAVES(SLAVES)
    ) controller_inst (
        .master_req(master_req),
        .addr(addr),
        .slave_sel(slave_sel)
    );

endmodule

// Crossbar controller submodule
module crossbar_controller #(
    parameter MASTERS = 2,
    parameter SLAVES = 4
)(
    input [MASTERS-1:0] master_req,
    input [MASTERS-1:0][7:0] addr,
    output [MASTERS-1:0][SLAVES-1:0] slave_sel
);

    genvar i;
    generate
        for(i=0; i<MASTERS; i=i+1) begin : gen_decoders
            addr_decoder #(
                .SLAVES(SLAVES)
            ) decoder_inst (
                .addr(addr[i]),
                .req(master_req[i]),
                .sel(slave_sel[i])
            );
        end
    endgenerate

endmodule

// Address decoder submodule with LUT-based modulo
module addr_decoder #(
    parameter SLAVES = 4
)(
    input [7:0] addr,
    input req,
    output reg [SLAVES-1:0] sel
);

    // LUT for modulo operation
    reg [2:0] mod_lut [0:255];
    reg [2:0] mod_result;
    
    // Initialize LUT
    initial begin
        for(int i=0; i<256; i=i+1) begin
            mod_lut[i] = i % SLAVES;
        end
    end

    always @* begin
        mod_result = mod_lut[addr];
        sel = req ? (1 << mod_result) : {SLAVES{1'b0}};
    end

endmodule