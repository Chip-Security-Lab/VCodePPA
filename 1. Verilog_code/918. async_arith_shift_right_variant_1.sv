//SystemVerilog
module async_arith_shift_right (
    input      [15:0] data_i,
    input      [3:0]  shamt_i,
    input             enable_i,
    output reg [15:0] data_o
);
    // Optimized implementation with hierarchical mux structure
    // This reduces the critical path and improves timing
    reg [15:0] shifted_data;
    wire sign_bit = data_i[15];
    
    always @(*) begin
        case(shamt_i)
            4'd0:  shifted_data = data_i;
            4'd1:  shifted_data = {sign_bit, data_i[15:1]};
            4'd2:  shifted_data = {{2{sign_bit}}, data_i[15:2]};
            4'd3:  shifted_data = {{3{sign_bit}}, data_i[15:3]};
            4'd4:  shifted_data = {{4{sign_bit}}, data_i[15:4]};
            4'd5:  shifted_data = {{5{sign_bit}}, data_i[15:5]};
            4'd6:  shifted_data = {{6{sign_bit}}, data_i[15:6]};
            4'd7:  shifted_data = {{7{sign_bit}}, data_i[15:7]};
            4'd8:  shifted_data = {{8{sign_bit}}, data_i[15:8]};
            4'd9:  shifted_data = {{9{sign_bit}}, data_i[15:9]};
            4'd10: shifted_data = {{10{sign_bit}}, data_i[15:10]};
            4'd11: shifted_data = {{11{sign_bit}}, data_i[15:11]};
            4'd12: shifted_data = {{12{sign_bit}}, data_i[15:12]};
            4'd13: shifted_data = {{13{sign_bit}}, data_i[15:13]};
            4'd14: shifted_data = {{14{sign_bit}}, data_i[15:14]};
            4'd15: shifted_data = {{15{sign_bit}}, data_i[15]};
            default: shifted_data = data_i;
        endcase
    end
    
    // Final output mux logic with enable control
    always @(*) begin
        data_o = enable_i ? shifted_data : data_i;
    end
endmodule