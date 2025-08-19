module MajorityVote #(parameter N=5, M=3) (
    input [N-1:0] inputs,
    output reg vote_out
);
    integer count, i;
    
    always @(*) begin
        count = 0;
        for(i=0; i<N; i=i+1)
            if(inputs[i]) count = count + 1;
        vote_out = (count >= M);
    end
endmodule