//SystemVerilog
module BiDirMux #(parameter DW=8) (
    inout  [DW-1:0]           bus,
    input  [(4*DW)-1:0]       tx,
    output [(4*DW)-1:0]       rx,
    input  [1:0]              sel,
    input                     oe
);

    // 2-bit shift-and-add multiplier submodule
    function [3:0] shift_add_mult2;
        input [1:0] a;
        input [1:0] b;
        reg [3:0] result;
        integer i;
        begin
            result = 4'b0000;
            for (i = 0; i < 2; i = i + 1) begin
                if (b[i])
                    result = result + (a << i);
            end
            shift_add_mult2 = result;
        end
    endfunction

    // Unroll bus receive logic
    assign rx[DW-1:0]     = (sel == 2'd0) ? bus : {DW{1'bz}};
    assign rx[2*DW-1:DW]  = (sel == 2'd1) ? bus : {DW{1'bz}};
    assign rx[3*DW-1:2*DW]= (sel == 2'd2) ? bus : {DW{1'bz}};
    assign rx[4*DW-1:3*DW]= (sel == 2'd3) ? bus : {DW{1'bz}};
    
    // Unroll bus control logic for synthesizability and PPA
    wire [DW-1:0] tx_mux0 = tx[DW-1:0];
    wire [DW-1:0] tx_mux1 = tx[2*DW-1:DW];
    wire [DW-1:0] tx_mux2 = tx[3*DW-1:2*DW];
    wire [DW-1:0] tx_mux3 = tx[4*DW-1:3*DW];

    // Example: apply shift-and-add 2-bit multiplier to lower 2 bits of tx_mux0 and tx_mux1
    // This is just an example; in real usage, instantiate as needed
    wire [3:0] tx_mult_result0;
    wire [3:0] tx_mult_result1;
    wire [3:0] tx_mult_result2;
    wire [3:0] tx_mult_result3;

    assign tx_mult_result0 = shift_add_mult2(tx_mux0[1:0], tx_mux1[1:0]);
    assign tx_mult_result1 = shift_add_mult2(tx_mux1[1:0], tx_mux2[1:0]);
    assign tx_mult_result2 = shift_add_mult2(tx_mux2[1:0], tx_mux3[1:0]);
    assign tx_mult_result3 = shift_add_mult2(tx_mux3[1:0], tx_mux0[1:0]);

    // Use the multiplier results as bus_driver for demonstration (replace as per actual requirement)
    wire [DW-1:0] bus_driver = (sel == 2'd0) ? {{(DW-4){1'b0}}, tx_mult_result0} :
                               (sel == 2'd1) ? {{(DW-4){1'b0}}, tx_mult_result1} :
                               (sel == 2'd2) ? {{(DW-4){1'b0}}, tx_mult_result2} :
                                               {{(DW-4){1'b0}}, tx_mult_result3};

    assign bus = oe ? bus_driver : {DW{1'bz}};

endmodule